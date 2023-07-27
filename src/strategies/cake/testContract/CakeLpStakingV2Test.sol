// pragma solidity ^0.8.0;

// import "@openzeppelin/token/ERC20/IERC20.sol";
// import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/access/Ownable.sol";
// import "@openzeppelin/security/Pausable.sol";
// import "@openzeppelin/security/ReentrancyGuard.sol";

// import "@rivera/strategies/cake/interfaces/libraries/ITickMathLib.sol";
// import "@rivera/strategies/cake/interfaces/libraries/ISqrtPriceMathLib.sol";
// import "@rivera/strategies/cake/interfaces/libraries/ILiquidityMathLib.sol";
// import "@rivera/strategies/cake/interfaces/libraries/ISafeCastLib.sol";
// import "@rivera/strategies/cake/interfaces/libraries/ILiquidityAmountsLib.sol";
// import "@rivera/strategies/cake/interfaces/libraries/IFullMathLib.sol";

// import "@pancakeswap-v3-core/interfaces/IPancakeV3Pool.sol";
// import "@pancakeswap-v3-core/libraries/FixedPoint96.sol";

// import "../interfaces/IMasterChefV3.sol";
// import "../interfaces/INonfungiblePositionManager.sol";
// import "../../common/AbstractStrategyV2.sol";
// import "@openzeppelin/token/ERC721/utils/ERC721Holder.sol";
// import "../interfaces/IV3SwapRouter.sol";

// struct CakePoolParams {
//     bool isTokenZeroDeposit;
//     int24 tickLower;
//     int24 tickUpper;
//     address stake;
//     address chef;
//     address reward;
//     address tickMathLib;
//     address sqrtPriceMathLib;
//     address liquidityMathLib;
//     address safeCastLib;
//     address liquidityAmountsLib;
//     address fullMathLib;
//     uint24 poolFee;
// }

// contract CakeLpStakingV2Test is
//     AbstractStrategyV2,
//     ReentrancyGuard,
//     ERC721Holder
// {
//     using SafeERC20 for IERC20;

//     // Tokens used
//     address public reward;
//     address public stake;
//     address public lpToken0;
//     address public lpToken1;
//     bool public isTokenZeroDeposit;

//     // Third party contracts
//     address public chef;
//     address public tickMathLib;
//     address public sqrtPriceMathLib;
//     address public liquidityMathLib;
//     address public safeCastLib;
//     address public liquidityAmountsLib;
//     address public fullMathLib;

//     uint256 public lastHarvest;
//     uint256 public tokenID;
//     int24 public tickLower;
//     int24 public tickUpper;
//     uint24 public poolFee;

//     //Events
//     event StratHarvest(
//         address indexed harvester,
//         uint256 stakeHarvested,
//         uint256 tvl
//     );
//     event Deposit(uint256 tvl, uint256 amount);
//     event Withdraw(uint256 tvl, uint256 amount);
//     event RangeChange(int24 tickLower, int24 tickUpper);

//     ///@dev
//     ///@param _cakePoolParams: Has the cake pool specific params
//     ///@param _commonAddresses: Has addresses common to all vaults, check Rivera Fee manager for more info
//     constructor(
//         CakePoolParams memory _cakePoolParams, //["0x36696169C63e42cd08ce11f5deeBbCeBae652050","0x556B9306565093C855AEA9AE92A594704c2Cd59e",["0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82","0x55d398326f99059ff775485246999027b3197955"],["0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82","0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"],true,-57260,-57170] -57760,57060 //usdt/bnb//usdt/bnb
//         CommonAddresses memory _commonAddresses //["vault","0x13f4EA83D0bd40E75C8222255bc855a974568Dd4","0x46A15B0b27311cedF172AB29E4f4766fbE7F4364"]
//     ) AbstractStrategyV2(_commonAddresses) {
//         stake = _cakePoolParams.stake;
//         chef = _cakePoolParams.chef;
//         tickLower = _cakePoolParams.tickLower;
//         tickUpper = _cakePoolParams.tickUpper;
//         isTokenZeroDeposit = _cakePoolParams.isTokenZeroDeposit;
//         reward = _cakePoolParams.reward;
//         tickMathLib = _cakePoolParams.tickMathLib;
//         sqrtPriceMathLib = _cakePoolParams.sqrtPriceMathLib;
//         liquidityMathLib = _cakePoolParams.liquidityMathLib;
//         safeCastLib = _cakePoolParams.safeCastLib;
//         liquidityAmountsLib = _cakePoolParams.liquidityAmountsLib;
//         poolFee = _cakePoolParams.poolFee;
//         fullMathLib = _cakePoolParams.fullMathLib;
//         lpToken0 = IPancakeV3Pool(stake).token0();
//         lpToken1 = IPancakeV3Pool(stake).token1();
//         _giveAllowances();
//     }

//     // puts the funds to work
//     function depositV3() public {
//         onlyVault();
//         if (tokenID == 0) {
//             userDepositSwap();
//             _deposit();
//         } else {
//             _increaseLiquidity();
//         }
//     }

//     function assetRatio()
//         public
//         view
//         returns (uint256 amount0Ratio, uint256 amount1Ratio)
//     {
//         int24 _tickLower = tickLower;
//         int24 _tickUpper = tickUpper;
//         IPancakeV3Pool pool = IPancakeV3Pool(stake);
//         (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
//         uint160 sqrtRatioAX96 = ITickMathLib(tickMathLib).getSqrtRatioAtTick(
//             _tickLower
//         );
//         uint160 sqrtRatioBX96 = ITickMathLib(tickMathLib).getSqrtRatioAtTick(
//             _tickUpper
//         );
//         uint128 liquidity = ILiquidityAmountsLib(liquidityAmountsLib)
//             .getLiquidityForAmounts(
//                 sqrtPriceX96,
//                 sqrtRatioAX96,
//                 sqrtRatioBX96,
//                 1e28,
//                 1e28
//             ); //We're simply defaulting amount0 desired and amount1 desired to 1e22 because we only care about the ratio of assets. Uniswap library will automatically figure out the limitting asset and give us the ratio.

//         int256 amount0Int;
//         int256 amount1Int;
//         if (liquidity != 0) {
//             if (tick < _tickLower) {
//                 // current tick is below the passed range; liquidity can only become in range by crossing from left to
//                 // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
//                 amount0Int = ISqrtPriceMathLib(sqrtPriceMathLib)
//                     .getAmount0Delta(
//                         ITickMathLib(tickMathLib).getSqrtRatioAtTick(
//                             _tickLower
//                         ),
//                         ITickMathLib(tickMathLib).getSqrtRatioAtTick(
//                             _tickUpper
//                         ),
//                         ISafeCastLib(safeCastLib).toInt128(
//                             int256(uint256(liquidity))
//                         )
//                     );
//             } else if (tick < _tickUpper) {
//                 // current tick is inside the passed range
//                 amount0Int = ISqrtPriceMathLib(sqrtPriceMathLib)
//                     .getAmount0Delta(
//                         sqrtPriceX96,
//                         ITickMathLib(tickMathLib).getSqrtRatioAtTick(
//                             _tickUpper
//                         ),
//                         ISafeCastLib(safeCastLib).toInt128(
//                             int256(uint256(liquidity))
//                         )
//                     );
//                 amount1Int = ISqrtPriceMathLib(sqrtPriceMathLib)
//                     .getAmount1Delta(
//                         ITickMathLib(tickMathLib).getSqrtRatioAtTick(
//                             _tickLower
//                         ),
//                         sqrtPriceX96,
//                         ISafeCastLib(safeCastLib).toInt128(
//                             int256(uint256(liquidity))
//                         )
//                     );
//             } else {
//                 // current tick is above the passed range; liquidity can only become in range by crossing from right to
//                 // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
//                 amount1Int = ISqrtPriceMathLib(sqrtPriceMathLib)
//                     .getAmount1Delta(
//                         ITickMathLib(tickMathLib).getSqrtRatioAtTick(
//                             _tickLower
//                         ),
//                         ITickMathLib(tickMathLib).getSqrtRatioAtTick(
//                             _tickUpper
//                         ),
//                         ISafeCastLib(safeCastLib).toInt128(
//                             int256(uint256(liquidity))
//                         )
//                     );
//             }
//         }
//         uint256 amount0 = uint256(amount0Int);
//         uint256 amount1 = uint256(amount1Int);
//         amount0Ratio = amount0;
//         amount1Ratio = IFullMathLib(fullMathLib).mulDiv(
//             amount1,
//             sqrtPriceX96 * sqrtPriceX96,
//             FixedPoint96.Q96 * FixedPoint96.Q96
//         ); //We're multiplying the required amount1 with the price of token1 in terms of token0 in order to get the ratio at which the deposit token has to be split. To convert sqrtPriceX96 into the price we have to divide it by 2**96 and squate it.
//     }

//     function splitAmountBasedOnRange(
//         uint256 amount
//     ) internal view returns (uint256 amountToken0, uint256 amountToken1) {
//         (uint256 amount0Ratio, uint256 amount1Ratio) = assetRatio();
//         if (amount0Ratio == 0) {
//             amountToken0 = 0;
//             amountToken1 = amount;
//         } else if (amount1Ratio == 0) {
//             amountToken1 = 0;
//             amountToken0 = amount;
//         } else {
//             amountToken0 = IFullMathLib(fullMathLib).mulDiv(
//                 amount,
//                 amount0Ratio,
//                 amount0Ratio + amount1Ratio
//             );
//             amountToken1 = IFullMathLib(fullMathLib).mulDiv(
//                 amount,
//                 amount1Ratio,
//                 amount0Ratio + amount1Ratio
//             );
//         }
//     }

//     //user stablecoin deposit swap
//     function userDepositSwap() internal {
//         address depositToken = getDepositToken();
//         uint256 depositAsset = IERC20(depositToken).balanceOf(address(this));
//         // (
//         //     uint256 depositAssetToken0,
//         //     uint256 depositAssetToken1
//         // ) = splitAmountBasedOnRange(depositAsset);

//         //Using Uniswap to convert half of the CAKE tokens into Liquidity Pair token 0
//         if (depositToken != lpToken0) {
//             _swapV3(depositToken, lpToken0, depositAsset / 2, poolFee);
//         }

//         if (depositToken != lpToken1) {
//             _swapV3(depositToken, lpToken1, depositAsset / 2, poolFee);
//         }

//         _mintAndAddLiquidityV3();
//     }

//     function _deposit() internal whenNotPaused nonReentrant {
//         //Entire LP balance of the strategy contract address is deployed to the farm to earn CAKE
//         INonfungiblePositionManager(NonfungiblePositionManager)
//             .safeTransferFrom(address(this), chef, tokenID);
//     }

//     function burnAndCollectV3() internal nonReentrant {
//         uint256 liquidity = balanceOfPool();
//         require(liquidity > 0, "No Liquidity available");
//         IMasterChefV3(chef).withdraw(tokenID, address(this)); //transfer the nft back to the user

//         INonfungiblePositionManager(NonfungiblePositionManager)
//             .decreaseLiquidity(
//                 INonfungiblePositionManager.DecreaseLiquidityParams(
//                     tokenID,
//                     uint128(liquidity),
//                     1,
//                     1,
//                     block.timestamp
//                 )
//             );

//         (
//             ,
//             ,
//             ,
//             ,
//             ,
//             ,
//             ,
//             ,
//             ,
//             ,
//             uint128 tokensOwed0,
//             uint128 tokensOwed1
//         ) = INonfungiblePositionManager(NonfungiblePositionManager).positions(
//                 tokenID
//             );

//         INonfungiblePositionManager(NonfungiblePositionManager).collect(
//             INonfungiblePositionManager.CollectParams(
//                 tokenID,
//                 address(this),
//                 tokensOwed0,
//                 tokensOwed1
//             )
//         );
//         INonfungiblePositionManager(NonfungiblePositionManager).burn(tokenID);
//     }

//     /// @dev Common checks for valid tick inputs.
//     function checkTicks(int24 tickLower_, int24 tickUpper_) private view {
//         require(tickLower_ < tickUpper_, "TLU");
//         require(tickLower_ >= ITickMathLib(tickMathLib).MIN_TICK(), "TLM");
//         require(tickUpper_ <= ITickMathLib(tickMathLib).MAX_TICK(), "TUM");
//     }

//     //{-52050,-42800}
//     function changeRange(int24 _tickLower, int24 _tickUpper) external {
//         _checkOwner();
//         require(
//             !(tickLower == _tickLower && tickUpper == _tickUpper),
//             "Range cannot be same"
//         );
//         checkTicks(_tickLower, _tickUpper);
//         int24 tickSpacing = IPancakeV3Pool(stake).tickSpacing();
//         require(
//             _tickLower % tickSpacing == 0 && _tickUpper % tickSpacing == 0,
//             "Invalid Ticks"
//         );
//         burnAndCollectV3();
//         tickLower = _tickLower;
//         tickUpper = _tickUpper;
//         _mintAndAddLiquidityV3();
//         _deposit();
//         emit RangeChange(tickLower, tickUpper);
//     }

//     //here _amount is liquidity amount and not deposited token amount
//     function withdraw(uint256 _amount) external nonReentrant {
//         //What if the entire liquidity of the LP is withdrawn? Should we not burn the NFT
//         onlyVault();
//         //Pretty Straight forward almost same as AAVE strategy
//         require(_amount <= balanceOfPool(), "Amount is too large");

//         (uint256 amount0, uint256 amount1) = IMasterChefV3(chef)
//             .decreaseLiquidity(
//                 INonfungiblePositionManager.DecreaseLiquidityParams(
//                     tokenID,
//                     uint128(_amount),
//                     1,
//                     1,
//                     block.timestamp
//                 )
//             );
//         IMasterChefV3(chef).collect(
//             INonfungiblePositionManager.CollectParams(
//                 tokenID,
//                 address(this),
//                 uint128(amount0),
//                 uint128(amount1)
//             )
//         );
//         _lptoDepositTokenSwap();
//         uint256 depositTokenBal = IERC20(getDepositToken()).balanceOf(
//             address(this)
//         );
//         IERC20(getDepositToken()).safeTransfer(vault, depositTokenBal);
//         emit Withdraw(balanceOf(), _amount);
//     }

//     function beforeDeposit() external virtual {}

//     function harvest() external virtual {
//         _harvest();
//     }

//     function managerHarvest() external {
//         onlyManager();
//         _harvest();
//     }

//     // compounds earnings and charges performance fee
//     function _harvest() internal whenNotPaused {
//         IMasterChefV3(chef).harvest(tokenID, address(this)); //it will transfer the CAKE rewards owed to the strategy.
//         //This essentially harvests the yeild from CAKE.
//         uint256 rewardBal = IERC20(reward).balanceOf(address(this)); //reward tokens will be CAKE. Cake balance of this strategy address will be zero before harvest.
//         if (rewardBal > 0) {
//             uint128 increasedLiquidity = addLiquidity(); //add liquidity to nfmanager and update liquidity at masterchef

//             lastHarvest = block.timestamp;
//             emit StratHarvest(
//                 msg.sender,
//                 uint256(increasedLiquidity),
//                 balanceOf()
//             );
//         }
//     }

//     // Adds liquidity to AMM and gets more LP tokens.
//     function addLiquidity() internal returns (uint128) {
//         //Should convert the CAKE tokens harvested into WOM and BUSD tokens and depost it in the liquidity pool. Get the LP tokens and stake it back to earn more CAKE.
//         uint256 rewardAmount = IERC20(reward).balanceOf(address(this)); //It says IUniswap here which might be inaccurate. If the address is that of pancake swap and method signatures match then the call should be made correctly.
//         (
//             uint256 rewardAmountToken0,
//             uint256 rewardAmountToken1
//         ) = splitAmountBasedOnRange(rewardAmount);

//         if (lpToken0 != reward) {
//             _swapV3(reward, lpToken0, rewardAmountToken0, 2500);
//         }

//         if (lpToken1 != reward) {
//             _swapV3(reward, lpToken1, rewardAmountToken1, 2500);
//         }

//         uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
//         uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

//         (uint128 liquidity, , ) = INonfungiblePositionManager(
//             NonfungiblePositionManager
//         ).increaseLiquidity(
//                 INonfungiblePositionManager.IncreaseLiquidityParams(
//                     tokenID,
//                     lp0Bal,
//                     lp1Bal,
//                     1,
//                     1,
//                     block.timestamp
//                 )
//             );
//         IMasterChefV3(chef).updateLiquidity(tokenID);
//         // Liquidity=uint128(balanceOf());
//         return liquidity;
//     }

//     function _mintAndAddLiquidityV3() internal {
//         uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
//         uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

//         (uint256 tokenId, , , ) = INonfungiblePositionManager(
//             NonfungiblePositionManager
//         ).mint(
//                 INonfungiblePositionManager.MintParams(
//                     lpToken0,
//                     lpToken1,
//                     500,
//                     tickLower,
//                     tickUpper,
//                     lp0Bal,
//                     lp1Bal,
//                     1,
//                     1,
//                     address(this),
//                     block.timestamp
//                 )
//             );
//         tokenID = tokenId;
//     }

//     function _lptoDepositTokenSwap() internal {
//         uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
//         uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
//         address depositToken = getDepositToken();
//         if (depositToken != lpToken0) {
//             _swapV3(lpToken0, depositToken, lp0Bal, poolFee);
//         }

//         if (depositToken != lpToken1) {
//             _swapV3(lpToken1, depositToken, lp1Bal, poolFee);
//         }
//     }

//     function _swapV3(
//         address tokenIn,
//         address tokenOut,
//         uint256 amount,
//         uint24 fee
//     ) internal {
//         IV3SwapRouter(router).exactInputSingle(
//             IV3SwapRouter.ExactInputSingleParams(
//                 tokenIn,
//                 tokenOut,
//                 fee,
//                 address(this),
//                 amount,
//                 1,
//                 0
//             )
//         );
//     }

//     // calculate the total underlaying 'stake' held by the strat.
//     function balanceOf() public view returns (uint256) {
//         // return balanceOfStake() + balanceOfPool();
//         return balanceOfPool();
//     }

//     // // it calculates how much 'stake' this contract holds.
//     // function balanceOfStake() public view returns (uint256) {
//     //     return IERC20(stake).balanceOf(address(this));
//     // }

//     // it calculates how much 'stake' the strategy has working in the farm.
//     function balanceOfPool() public view returns (uint256) {
//         //This function is returning in terms of liquidity I want it in terms of asset tokens
//         //_amount is the LP token amount the user has provided to stake
//         (uint256 liquidity, , , , , , , , ) = IMasterChefV3(chef)
//             .userPositionInfos(tokenID);
//         return liquidity;
//     }

//     // returns rewards unharvested
//     function rewardsAvailable() public view returns (uint256) {
//         //Returns the rewards available to the strategy contract from the pool
//         uint256 rewardsAvbl = IMasterChefV3(chef).pendingCake(tokenID);
//         return rewardsAvbl;
//     }

//     // called as part of strat migration. Sends all the available funds back to the vault.
//     function retireStrat() external {
//         onlyVault();
//         burnAndCollectV3();
//         _lptoDepositTokenSwap();
//         uint256 depositTokenBal = IERC20(getDepositToken()).balanceOf(
//             address(this)
//         );
//         IERC20(getDepositToken()).safeTransfer(vault, depositTokenBal);
//     }

//     // pauses deposits and withdraws all funds from third party systems.
//     function panic() public {
//         onlyManager();
//         pause();
//         burnAndCollectV3();
//         _lptoDepositTokenSwap();
//         uint256 depositTokenBal = IERC20(getDepositToken()).balanceOf(
//             address(this)
//         );
//         IERC20(getDepositToken()).safeTransfer(vault, depositTokenBal);
//     }

//     function getDepositToken() public view returns (address) {
//         if (isTokenZeroDeposit) {
//             return lpToken0;
//         } else {
//             return lpToken1;
//         }
//     }

//     function pause() public {
//         onlyManager();
//         _pause();

//         _removeAllowances();
//     }

//     function unpause() external {
//         onlyManager();
//         _unpause();

//         _giveAllowances();

//         // _deposit();
//     }

//     function _giveAllowances() internal {
//         // IERC20(stake).safeApprove(chef, type(uint256).max);
//         IERC20(reward).safeApprove(router, type(uint256).max);

//         IERC20(lpToken0).safeApprove(router, 0);
//         IERC20(lpToken0).safeApprove(router, type(uint256).max);

//         IERC20(lpToken1).safeApprove(router, 0);
//         IERC20(lpToken1).safeApprove(router, type(uint256).max);

//         IERC20(lpToken0).safeApprove(NonfungiblePositionManager, 0);
//         IERC20(lpToken0).safeApprove(
//             NonfungiblePositionManager,
//             type(uint256).max
//         );

//         IERC20(lpToken1).safeApprove(NonfungiblePositionManager, 0);
//         IERC20(lpToken1).safeApprove(
//             NonfungiblePositionManager,
//             type(uint256).max
//         );
//     }

//     function _removeAllowances() internal {
//         IERC20(stake).safeApprove(chef, 0);
//         IERC20(reward).safeApprove(router, 0);
//         IERC20(lpToken0).safeApprove(router, 0);
//         IERC20(lpToken1).safeApprove(router, 0);
//     }

//     //dummy functions

//     function _increaseLiquidity() public {
//         address depositToken = getDepositToken();
//         uint256 depositAsset = IERC20(depositToken).balanceOf(address(this));
//         (
//             uint256 depositAssetToken0,
//             uint256 depositAssetToken1
//         ) = splitAmountBasedOnRange(depositAsset);
//         //Using Uniswap to convert half of the CAKE tokens into Liquidity Pair token 0
//         if (depositToken != lpToken0) {
//             _swapV3(depositToken, lpToken0, depositAssetToken0, poolFee);
//         }

//         if (depositToken != lpToken1) {
//             _swapV3(depositToken, lpToken1, depositAssetToken1, poolFee);
//         }
//         uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
//         uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

//         (uint128 liquidity, , ) = INonfungiblePositionManager(
//             NonfungiblePositionManager
//         ).increaseLiquidity(
//                 INonfungiblePositionManager.IncreaseLiquidityParams(
//                     tokenID,
//                     lp0Bal,
//                     lp1Bal,
//                     1,
//                     1,
//                     block.timestamp
//                 )
//             );
//         IMasterChefV3(chef).updateLiquidity(tokenID);
//     }

//     //end dummy functions
// }
