pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/Pausable.sol";
import "@openzeppelin/security/ReentrancyGuard.sol";

import "@rivera/strategies/cake/interfaces/libraries/ITickMathLib.sol";
import "@rivera/strategies/cake/interfaces/libraries/ISqrtPriceMathLib.sol";
import "@rivera/strategies/cake/interfaces/libraries/ILiquidityMathLib.sol";
import "@rivera/strategies/cake/interfaces/libraries/ISafeCastLib.sol";
import "@rivera/strategies/cake/interfaces/libraries/ILiquidityAmountsLib.sol";
import "@rivera/strategies/cake/interfaces/libraries/IFullMathLib.sol";

import "@pancakeswap-v3-core/libraries/FixedPoint96.sol";

import "./interfaces/IMasterChefV3.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "../common/AbstractStrategyV2.sol";
import "@openzeppelin/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IV3SwapRouter.sol";

//uniswap
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

struct CakePoolParams {
    bool isTokenZeroDeposit;
    int24 tickLower;
    int24 tickUpper;
    address stake;
    address tickMathLib;
    address sqrtPriceMathLib;
    address liquidityMathLib;
    address safeCastLib;
    address liquidityAmountsLib;
    address fullMathLib;
    uint24 poolFee;
}

contract UniswapStaking is AbstractStrategyV2, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    // Tokens used
    address public stake;
    address public lpToken0;
    address public lpToken1;
    bool public isTokenZeroDeposit;

    // Third party contracts
    address public tickMathLib;
    address public sqrtPriceMathLib;
    address public liquidityMathLib;
    address public safeCastLib;
    address public liquidityAmountsLib;
    address public fullMathLib;

    uint256 public lastHarvest;
    uint256 public tokenID;
    int24 public tickLower;
    int24 public tickUpper;
    uint24 public poolFee;

    //Events
    event StratHarvest(
        address indexed harvester,
        uint256 stakeHarvested,
        uint256 tvl
    );
    event Deposit(uint256 tvl, uint256 amount);
    event Withdraw(uint256 tvl, uint256 amount);
    event RangeChange(int24 tickLower, int24 tickUpper);

    ///@dev
    ///@param _cakePoolParams: Has the cake pool specific params
    ///@param _commonAddresses: Has addresses common to all vaults, check Rivera Fee manager for more info
    constructor(
        CakePoolParams memory _cakePoolParams,
        CommonAddresses memory _commonAddresses
    ) AbstractStrategyV2(_commonAddresses) {
        stake = _cakePoolParams.stake;
        tickLower = _cakePoolParams.tickLower;
        tickUpper = _cakePoolParams.tickUpper;
        isTokenZeroDeposit = _cakePoolParams.isTokenZeroDeposit;
        tickMathLib = _cakePoolParams.tickMathLib;
        sqrtPriceMathLib = _cakePoolParams.sqrtPriceMathLib;
        liquidityMathLib = _cakePoolParams.liquidityMathLib;
        safeCastLib = _cakePoolParams.safeCastLib;
        liquidityAmountsLib = _cakePoolParams.liquidityAmountsLib;
        fullMathLib = _cakePoolParams.fullMathLib;
        poolFee = _cakePoolParams.poolFee;
        _giveAllowances();
    }

    // puts the funds to work
    function depositV3() public {
        onlyVault();
        if (tokenID == 0) {
            userDepositSwap();
        } else {
            _increaseLiquidity();
        }
    }

    function assetRatio()
        public
        view
        returns (uint256 amount0Ratio, uint256 amount1Ratio)
    {
        int24 _tickLower = tickLower;
        int24 _tickUpper = tickUpper;
        IUniswapV3Pool pool = IUniswapV3Pool(stake);
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = ITickMathLib(tickMathLib).getSqrtRatioAtTick(
            _tickLower
        );
        uint160 sqrtRatioBX96 = ITickMathLib(tickMathLib).getSqrtRatioAtTick(
            _tickUpper
        );
        uint128 liquidity = ILiquidityAmountsLib(liquidityAmountsLib)
            .getLiquidityForAmounts(
                sqrtPriceX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                1e28,
                1e28
            ); //We're simply defaulting amount0 desired and amount1 desired to 1e22 because we only care about the ratio of assets. Uniswap library will automatically figure out the limitting asset and give us the ratio.

        int256 amount0Int;
        int256 amount1Int;
        if (liquidity != 0) {
            if (tick < _tickLower) {
                // current tick is below the passed range; liquidity can only become in range by crossing from left to
                // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
                amount0Int = ISqrtPriceMathLib(sqrtPriceMathLib)
                    .getAmount0Delta(
                        ITickMathLib(tickMathLib).getSqrtRatioAtTick(
                            _tickLower
                        ),
                        ITickMathLib(tickMathLib).getSqrtRatioAtTick(
                            _tickUpper
                        ),
                        ISafeCastLib(safeCastLib).toInt128(
                            int256(uint256(liquidity))
                        )
                    );
            } else if (tick < _tickUpper) {
                // current tick is inside the passed range
                amount0Int = ISqrtPriceMathLib(sqrtPriceMathLib)
                    .getAmount0Delta(
                        sqrtPriceX96,
                        ITickMathLib(tickMathLib).getSqrtRatioAtTick(
                            _tickUpper
                        ),
                        ISafeCastLib(safeCastLib).toInt128(
                            int256(uint256(liquidity))
                        )
                    );
                amount1Int = ISqrtPriceMathLib(sqrtPriceMathLib)
                    .getAmount1Delta(
                        ITickMathLib(tickMathLib).getSqrtRatioAtTick(
                            _tickLower
                        ),
                        sqrtPriceX96,
                        ISafeCastLib(safeCastLib).toInt128(
                            int256(uint256(liquidity))
                        )
                    );
            } else {
                // current tick is above the passed range; liquidity can only become in range by crossing from right to
                // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
                amount1Int = ISqrtPriceMathLib(sqrtPriceMathLib)
                    .getAmount1Delta(
                        ITickMathLib(tickMathLib).getSqrtRatioAtTick(
                            _tickLower
                        ),
                        ITickMathLib(tickMathLib).getSqrtRatioAtTick(
                            _tickUpper
                        ),
                        ISafeCastLib(safeCastLib).toInt128(
                            int256(uint256(liquidity))
                        )
                    );
            }
        }
        uint256 amount0 = uint256(amount0Int);
        uint256 amount1 = uint256(amount1Int);
        amount0Ratio = amount0;
        amount1Ratio = IFullMathLib(fullMathLib).mulDiv(
            amount1,
            sqrtPriceX96 * sqrtPriceX96,
            FixedPoint96.Q96 * FixedPoint96.Q96
        ); //We're multiplying the required amount1 with the price of token1 in terms of token0 in order to get the ratio at which the deposit token has to be split. To convert sqrtPriceX96 into the price we have to divide it by 2**96 and squate it.
    }

    function splitAmountBasedOnRange(
        uint256 amount
    ) internal view returns (uint256 amountToken0, uint256 amountToken1) {
        (uint256 amount0Ratio, uint256 amount1Ratio) = assetRatio();
        if (amount0Ratio == 0) {
            amountToken0 = 0;
            amountToken1 = amount;
        } else if (amount1Ratio == 0) {
            amountToken1 = 0;
            amountToken0 = amount;
        } else {
            amountToken0 = IFullMathLib(fullMathLib).mulDiv(
                amount,
                amount0Ratio,
                amount0Ratio + amount1Ratio
            );
            amountToken1 = IFullMathLib(fullMathLib).mulDiv(
                amount,
                amount1Ratio,
                amount0Ratio + amount1Ratio
            );
        }
    }

    //user stablecoin deposit swap
    function userDepositSwap() internal {
        address depositToken = getDepositToken();
        uint256 depositAsset = IERC20(depositToken).balanceOf(address(this));
        (
            uint256 depositAssetToken0,
            uint256 depositAssetToken1
        ) = splitAmountBasedOnRange(depositAsset);

        //Using Uniswap to convert half of the CAKE tokens into Liquidity Pair token 0
        if (depositToken != lpToken0) {
            _swapV3(depositToken, lpToken0, depositAssetToken0, poolFee);
        }

        if (depositToken != lpToken1) {
            _swapV3(depositToken, lpToken1, depositAssetToken1, poolFee);
        }

        _mintAndAddLiquidityV3();
    }

    function burnAndCollectV3() internal nonReentrant {
        uint256 liquidity = balanceOfPool();
        require(liquidity > 0, "No Liquidity available");

        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: tokenID,
                    liquidity: uint128(liquidity),
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
        INonfungiblePositionManager(NonfungiblePositionManager)
            .decreaseLiquidity(params);

        collectAllFees();
        INonfungiblePositionManager(NonfungiblePositionManager).burn(tokenID);
    }

    /// @dev Common checks for valid tick inputs.
    function checkTicks(int24 tickLower_, int24 tickUpper_) private view {
        require(tickLower_ < tickUpper_, "TLU");
        require(tickLower_ >= ITickMathLib(tickMathLib).MIN_TICK(), "TLM");
        require(tickUpper_ <= ITickMathLib(tickMathLib).MAX_TICK(), "TUM");
    }

    //{-52050,-42800}
    function changeRange(int24 _tickLower, int24 _tickUpper) external {
        _checkOwner();
        require(
            !(tickLower == _tickLower && tickUpper == _tickUpper),
            "Range cannot be same"
        );
        checkTicks(_tickLower, _tickUpper);
        int24 tickSpacing = IUniswapV3Pool(stake).tickSpacing();
        require(
            _tickLower % tickSpacing == 0 && _tickUpper % tickSpacing == 0,
            "Invalid Ticks"
        );
        burnAndCollectV3();
        tickLower = _tickLower;
        tickUpper = _tickUpper;
        _mintAndAddLiquidityV3();
        emit RangeChange(tickLower, tickUpper);
    }

    //here _amount is liquidity amount and not deposited token amount
    function withdraw(uint256 _amount) external nonReentrant {
        //What if the entire liquidity of the LP is withdrawn? Should we not burn the NFT
        onlyVault();
        //Pretty Straight forward almost same as AAVE strategy
        require(_amount <= balanceOfPool(), "Amount is too large");

        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: tokenID,
                    liquidity: uint128(_amount),
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
        INonfungiblePositionManager(NonfungiblePositionManager)
            .decreaseLiquidity(params);
        collectAllFees();
        _lptoDepositTokenSwap();
        uint256 depositTokenBal = IERC20(getDepositToken()).balanceOf(
            address(this)
        );
        IERC20(getDepositToken()).safeTransfer(vault, depositTokenBal);
        emit Withdraw(balanceOf(), _amount);
    }

    function beforeDeposit() external virtual {}

    function harvest() external virtual {
        _harvest();
    }

    function managerHarvest() external {
        onlyManager();
        _harvest();
    }

    // compounds earnings and charges performance fee
    function _harvest() internal whenNotPaused {
        collectAllFees();
        uint128 increasedLiquidity = addLiquidity();
        lastHarvest = block.timestamp;
        emit StratHarvest(msg.sender, uint256(increasedLiquidity), balanceOf());
    }

    function collectAllFees()
        internal
        returns (uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenID,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).collect(params);
        return (amount0, amount0);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal returns (uint128) {
        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: tokenID,
                    amount0Desired: lp0Bal,
                    amount1Desired: lp1Bal,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
        (uint256 liquidity, , ) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).increaseLiquidity(params);
        // Liquidity=uint128(balanceOf());
        return uint128(liquidity);
    }

    function _mintAndAddLiquidityV3() internal {
        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: lpToken0,
                token1: lpToken1,
                fee: poolFee,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: lp0Bal,
                amount1Desired: lp1Bal,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });
        (uint256 tokenId, , , ) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).mint(params);

        tokenID = tokenId;
    }

    function _lptoDepositTokenSwap() internal {
        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        address depositToken = getDepositToken();
        if (depositToken != lpToken0) {
            _swapV3(lpToken0, depositToken, lp0Bal, poolFee);
        }

        if (depositToken != lpToken1) {
            _swapV3(lpToken1, depositToken, lp1Bal, poolFee);
        }
    }

    function _swapV3(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint24 fee
    ) internal {
        IV3SwapRouter(router).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                tokenIn,
                tokenOut,
                fee,
                address(this),
                amount,
                1,
                0
            )
        );
    }

    // calculate the total underlaying 'stake' held by the strat.
    function balanceOf() public view returns (uint256) {
        // return balanceOfStake() + balanceOfPool();
        return balanceOfPool();
    }

    // // it calculates how much 'stake' this contract holds.
    // function balanceOfStake() public view returns (uint256) {
    //     return IERC20(stake).balanceOf(address(this));
    // }

    // it calculates how much 'stake' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        //_amount is the LP token amount the user has provided to stake
        (, , , , , , , uint128 liquidity, , , , ) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).positions(tokenID);
        return uint256(liquidity);
    }

    // // returns rewards unharvested
    // function rewardsAvailable() public view returns (uint256) {
    //     //Returns the rewards available to the strategy contract from the pool
    //     uint256 rewardsAvbl = IMasterChefV3(chef).pendingCake(tokenID);
    //     return rewardsAvbl;
    // }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        onlyVault();
        burnAndCollectV3();
        _lptoDepositTokenSwap();
        uint256 depositTokenBal = IERC20(getDepositToken()).balanceOf(
            address(this)
        );
        IERC20(getDepositToken()).safeTransfer(vault, depositTokenBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public {
        onlyManager();
        pause();
        burnAndCollectV3();
        _lptoDepositTokenSwap();
        uint256 depositTokenBal = IERC20(getDepositToken()).balanceOf(
            address(this)
        );
        IERC20(getDepositToken()).safeTransfer(vault, depositTokenBal);
    }

    function getDepositToken() public view returns (address) {
        if (isTokenZeroDeposit) {
            return lpToken0;
        } else {
            return lpToken1;
        }
    }

    function pause() public {
        onlyManager();
        _pause();

        _removeAllowances();
    }

    function unpause() external {
        onlyManager();
        _unpause();

        _giveAllowances();

        // _deposit();
    }

    function _giveAllowances() internal {
        // IERC20(stake).safeApprove(chef, type(uint256).max);

        IERC20(lpToken0).safeApprove(router, 0);
        IERC20(lpToken0).safeApprove(router, type(uint256).max);

        IERC20(lpToken1).safeApprove(router, 0);
        IERC20(lpToken1).safeApprove(router, type(uint256).max);

        IERC20(lpToken0).safeApprove(NonfungiblePositionManager, 0);
        IERC20(lpToken0).safeApprove(
            NonfungiblePositionManager,
            type(uint256).max
        );

        IERC20(lpToken1).safeApprove(NonfungiblePositionManager, 0);
        IERC20(lpToken1).safeApprove(
            NonfungiblePositionManager,
            type(uint256).max
        );
    }

    function _removeAllowances() internal {
        IERC20(lpToken0).safeApprove(router, 0);
        IERC20(lpToken1).safeApprove(router, 0);
    }

    //dummy functions

    function _increaseLiquidity() public {
        address depositToken = getDepositToken();
        uint256 depositAsset = IERC20(depositToken).balanceOf(address(this));
        (
            uint256 depositAssetToken0,
            uint256 depositAssetToken1
        ) = splitAmountBasedOnRange(depositAsset);
        //Using Uniswap to convert half of the CAKE tokens into Liquidity Pair token 0
        if (depositToken != lpToken0) {
            _swapV3(depositToken, lpToken0, depositAssetToken0, poolFee);
        }

        if (depositToken != lpToken1) {
            _swapV3(depositToken, lpToken1, depositAssetToken1, poolFee);
        }
        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: tokenID,
                    amount0Desired: lp0Bal,
                    amount1Desired: lp1Bal,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
        INonfungiblePositionManager(NonfungiblePositionManager)
            .increaseLiquidity(params);
    }

    //end dummy functions
}
