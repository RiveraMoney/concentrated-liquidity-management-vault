pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/Pausable.sol";
import "@openzeppelin/security/ReentrancyGuard.sol";

import "@pancakeswap-v3-core/interfaces/IPancakeV3Pool.sol";

import "./interfaces/IMasterChefV3.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "../common/FeeManager.sol";
import "../utils/StringUtils.sol";
import "@openzeppelin/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/proxy/utils/Initializable.sol";
import "./interfaces/IV3SwapRouter.sol";

import "@rivera/libs/DexV3Calculations.sol";
import "@rivera/libs/DexV3CalculationStruct.sol";

struct RiveraLpStakingParams {
    int24 tickLower;
    int24 tickUpper;
    address stake;
    address chef;
    address reward;
    address tickMathLib;
    address sqrtPriceMathLib;
    address liquidityMathLib;
    address safeCastLib;
    address liquidityAmountsLib;
    address fullMathLib;
    address[] rewardToLp0AddressPath;
    uint24[] rewardToLp0FeePath;
    address[] rewardToLp1AddressPath;
    uint24[] rewardToLp1FeePath;
    address  rewardtoNativeFeed;
    address  assettoNativeFeed;
    string pendingRewardsFunctionName;
}

struct CommonAddresses {
    address vault;
    address router;
    address NonfungiblePositionManager;

    uint256 withdrawFeeDecimals;
    uint256 withdrawFee;

    uint256 feeDecimals;
    uint256 protocolFee;
    uint256 fundManagerFee;
    uint256 partnerFee;
    address partner;
}

contract RiveraConcLpStakingGen is FeeManager, ReentrancyGuard, ERC721Holder, Initializable {
    using SafeERC20 for IERC20;

    // Tokens used
    address public reward;
    address public stake;
    address public lpToken0;
    address public lpToken1;
    address public depositToken;
    bool public hasFarm;

    // Third party contracts
    address public chef;
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

    address[] public rewardToLp0AddressPath;
    uint24[] public rewardToLp0FeePath;

    address[] public rewardToLp1AddressPath;
    uint24[] public rewardToLp1FeePath;
    address public rewardtoNativeFeed;
    string public pendingRewardsFunctionName;
    address public assettoNativeFeed;

    //Events
    event StratHarvest(
        address indexed harvester,
        uint256 stakeHarvested,
        uint256 tvl
    );
    event Deposit(uint256 tvl, uint256 amount);
    event Withdraw(uint256 tvl, uint256 amount);
    event RangeChange(int24 tickLower, int24 tickUpper);
    event RewardToLp0PathChange(address[] newRewardToLp0AddressPath, uint24[] newRewardToLp0FeePath);
    event RewardToLp1PathChange(address[] newRewardToLp1AddressPath, uint24[] newRewardToLp1FeePath);
    // event RewardToNativeFeedChange(address oldFeed, address newFeed);
    // event AssetToNativeFeedChange(address oldFeed, address newFeed);

    ///@dev
    ///@param _riveraLpStakingParams: Has the pool specific params
    ///@param _commonAddresses: Has addresses common to all vaults, check Rivera Fee manager for more info
    function init(RiveraLpStakingParams memory _riveraLpStakingParams, CommonAddresses memory _commonAddresses) public virtual initializer {
        tickMathLib = _riveraLpStakingParams.tickMathLib;
        sqrtPriceMathLib = _riveraLpStakingParams.sqrtPriceMathLib;
        liquidityMathLib = _riveraLpStakingParams.liquidityMathLib;
        safeCastLib = _riveraLpStakingParams.safeCastLib;
        liquidityAmountsLib = _riveraLpStakingParams.liquidityAmountsLib;
        fullMathLib = _riveraLpStakingParams.fullMathLib;
        stake = _riveraLpStakingParams.stake;
        chef = _riveraLpStakingParams.chef;
        reward = _riveraLpStakingParams.reward;
        require(_riveraLpStakingParams.rewardToLp0FeePath.length == _riveraLpStakingParams.rewardToLp0AddressPath.length - 1, "IP");
        require(_riveraLpStakingParams.rewardToLp1FeePath.length == _riveraLpStakingParams.rewardToLp1AddressPath.length - 1, "IP");
        rewardToLp0AddressPath = _riveraLpStakingParams.rewardToLp0AddressPath;
        rewardToLp0FeePath = _riveraLpStakingParams.rewardToLp0FeePath;
        rewardToLp1AddressPath = _riveraLpStakingParams.rewardToLp1AddressPath;
        rewardToLp1FeePath = _riveraLpStakingParams.rewardToLp1FeePath;
        DexV3Calculations.checkTicks(0, 0, _riveraLpStakingParams.tickLower, _riveraLpStakingParams.tickUpper, tickMathLib, stake);
        tickLower = _riveraLpStakingParams.tickLower;
        tickUpper = _riveraLpStakingParams.tickUpper;
        poolFee = IPancakeV3Pool(stake).fee();
        lpToken0 = IPancakeV3Pool(stake).token0();
        lpToken1 = IPancakeV3Pool(stake).token1();
        (bool success, bytes memory data) = _commonAddresses.vault.call(abi.encodeWithSelector(bytes4(keccak256(bytes('asset()')))));
        require(success, "AF");
        depositToken = abi.decode(data, (address));
        rewardtoNativeFeed = _riveraLpStakingParams.rewardtoNativeFeed;
        assettoNativeFeed = _riveraLpStakingParams.assettoNativeFeed;
        vault = _commonAddresses.vault;
        router = _commonAddresses.router;
        manager = msg.sender;
        NonfungiblePositionManager = _commonAddresses.NonfungiblePositionManager;
        pendingRewardsFunctionName=_riveraLpStakingParams.pendingRewardsFunctionName;

        withdrawFeeDecimals = _commonAddresses.withdrawFeeDecimals;
        withdrawFee = _commonAddresses.withdrawFee;

        feeDecimals = _commonAddresses.feeDecimals;
        protocolFee = _commonAddresses.protocolFee;
        fundManagerFee = _commonAddresses.fundManagerFee;
        partnerFee = _commonAddresses.partnerFee;
        partner = _commonAddresses.partner;
        hasFarm=_riveraLpStakingParams.chef==address(0)?false:true;
        _giveAllowances();
    }

    function deposit() public virtual whenNotPaused {
        onlyVault();
        _deposit();
    }

    function _deposit() internal virtual {
        _swapAssetsToNewRangeRatio();
        _depositV3();
        IERC20(depositToken).safeTransfer(vault, _lptoDepositTokenSwap(IERC20(lpToken0).balanceOf(address(this)), IERC20(lpToken1).balanceOf(address(this))));
    }

    // puts the funds to work
    function _depositV3() internal {
        if (tokenID == 0) {         //Strategy does not have an active non fungible liquidity position
            _mintAndAddLiquidityV3();
            if(hasFarm) {
                _stakeNonFungibleLiquidityPosition();
            }
        } else {
            _increaseLiquidity();
        }
    }

    function _mintAndAddLiquidityV3() internal {
        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

        (uint256 tokenId, , , ) = INonfungiblePositionManager(
            NonfungiblePositionManager
        ).mint(
                INonfungiblePositionManager.MintParams(
                    lpToken0,
                    lpToken1,
                    poolFee,
                    tickLower,
                    tickUpper,
                    lp0Bal,
                    lp1Bal,
                    0,
                    0,
                    address(this),
                    block.timestamp
                )
            );
        tokenID = tokenId;
    }

    function _stakeNonFungibleLiquidityPosition() internal whenNotPaused nonReentrant {
        INonfungiblePositionManager(NonfungiblePositionManager)
            .safeTransferFrom(address(this), chef, tokenID);
    }

    function _increaseLiquidity() internal {
        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));

        INonfungiblePositionManager(
            NonfungiblePositionManager
        ).increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams(
                    tokenID,
                    lp0Bal,
                    lp1Bal,
                    0,
                    0,
                    block.timestamp
                )
            );
        if(hasFarm){
            IMasterChefV3(chef).updateLiquidity(tokenID);
        }
        // IMasterChefV3(chef).updateLiquidity(tokenID);
    }

    function _burnAndCollectV3() public nonReentrant returns (uint256 amount0, uint256 amount1) {
        uint128 liquidity = liquidityBalance();
        require(liquidity > 0, "No Liquidity available");
        if(hasFarm){
            IMasterChefV3(chef).withdraw(tokenID, address(this)); //transfer the nft back to the user
        }

        INonfungiblePositionManager(NonfungiblePositionManager)
            .decreaseLiquidity(
                INonfungiblePositionManager.DecreaseLiquidityParams(
                    tokenID,
                    liquidity,
                    0,
                    0,
                    block.timestamp
                )
            );

        (amount0, amount1) = INonfungiblePositionManager(NonfungiblePositionManager).collect(
            INonfungiblePositionManager.CollectParams(
                tokenID,
                address(this),
                type(uint128).max,
                type(uint128).max
            )
        );
        INonfungiblePositionManager(NonfungiblePositionManager).burn(tokenID);
        tokenID = 0;
    }

    /// @dev Function to change the asset holding of the strategy contract to new ratio that is the result of change range
    function _swapAssetsToNewRangeRatio() internal {      //lib
        uint256 currAmount0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 currAmount1Bal = IERC20(lpToken1).balanceOf(address(this));
        (uint256 x, uint256 y) = DexV3Calculations.changeInAmountsToNewRangeRatio(LiquidityToAmountCalcParams(tickLower, tickUpper, 1e28, safeCastLib, sqrtPriceMathLib, tickMathLib, stake), 
        ChangeInAmountsForNewRatioParams(poolFee, currAmount0Bal, currAmount1Bal, fullMathLib));
        if (x!=0) {
            _swapV3In(lpToken0, lpToken1, x, poolFee);
        }
        if (y!=0) {
            _swapV3In(lpToken1, lpToken0, y, poolFee);
        }
    }

    //{-52050,-42800}
    function changeRange(int24 _tickLower, int24 _tickUpper) external virtual {
        _checkOwner();
        DexV3Calculations.checkTicks(tickLower, tickUpper, _tickLower, _tickUpper, tickMathLib, stake);
        _burnAndCollectV3();        //This will return token0 and token1 in a ratio that is corresponding to the current range not the one we're setting it to
        tickLower = _tickLower;
        tickUpper = _tickUpper;
        _deposit();
        emit RangeChange(tickLower, tickUpper);
    }

    function _withdrawV3(uint256 _amount) internal returns (uint256 userAmount0,  uint256 userAmount1) {
        uint128 liquidityDelta = DexV3Calculations.calculateLiquidityDeltaForAssetAmount(LiquidityToAmountCalcParams(tickLower, tickUpper, 1e28, safeCastLib, sqrtPriceMathLib, tickMathLib, stake), 
        LiquidityDeltaForAssetAmountParams(depositToken == lpToken0, poolFee, _amount, fullMathLib, liquidityAmountsLib));
        uint128 liquidityAvlbl = liquidityBalance();
        if (liquidityDelta > liquidityAvlbl) {
            liquidityDelta = liquidityAvlbl;
        }
        if(hasFarm){
            IMasterChefV3(chef).decreaseLiquidity(
                    INonfungiblePositionManager.DecreaseLiquidityParams(
                        tokenID,
                        liquidityDelta,
                        0,
                        0,
                        block.timestamp
                    )
            );
        }else{
            INonfungiblePositionManager(NonfungiblePositionManager).decreaseLiquidity(
                    INonfungiblePositionManager.DecreaseLiquidityParams(
                        tokenID,
                        liquidityDelta,
                        0,
                        0,
                        block.timestamp
                    )
            );
        }
        if(hasFarm){
            (userAmount0, userAmount1) = IMasterChefV3(chef).collect(INonfungiblePositionManager.CollectParams(
                        tokenID,
                        address(this),
                        type(uint128).max,
                        type(uint128).max
                    ));
        }else{
            (userAmount0, userAmount1) = INonfungiblePositionManager(NonfungiblePositionManager).collect(
            INonfungiblePositionManager.CollectParams(
                tokenID,
                address(this),
                type(uint128).max,
                type(uint128).max
            ));
        }
    }

    //here _amount is liquidity amount and not deposited token amount
    function withdraw(uint256 _amount) external virtual nonReentrant {
        onlyVault();
        (uint256 userAmount0, uint256 userAmount1) = _withdrawV3(_amount);
        uint256 withdrawAmount = _lptoDepositTokenSwap(userAmount0, userAmount1);
        IERC20(depositToken).safeTransfer(vault, withdrawAmount - withdrawAmount * withdrawFee / withdrawFeeDecimals);
        emit Withdraw(balanceOf(), _amount);
    }

    function harvest() external virtual {
        _requireNotPaused();
        if(hasFarm){
            IMasterChefV3(chef).harvest(tokenID, address(this));
        }
        uint256 rewardBal = IERC20(reward).balanceOf(address(this));
        if (rewardBal > 0) {
            if (lpToken0 != reward && lpToken0 == depositToken) {
                _swapV3PathIn(rewardToLp0AddressPath, rewardToLp0FeePath, rewardBal);
            }

            if (lpToken1 != reward && lpToken1 == depositToken) {
                _swapV3PathIn(rewardToLp1AddressPath, rewardToLp1FeePath, rewardBal);
            }

            lastHarvest = block.timestamp;
        }
        if(hasFarm){
            IMasterChefV3(chef).collect(
            INonfungiblePositionManager.CollectParams(
                tokenID,
                address(this),
                type(uint128).max,
                type(uint128).max
            )
            );
        }else{
            INonfungiblePositionManager(NonfungiblePositionManager).collect(
            INonfungiblePositionManager.CollectParams(
                tokenID,
                address(this),
                type(uint128).max,
                type(uint128).max
            )
            );
        }
        
        _chargeFees(lpToken0);
        _chargeFees(lpToken1);
        _deposit();
        emit StratHarvest(
                msg.sender,
                rewardBal,
                balanceOf()
            );
    }

    function _chargeFees(address token) internal {
        uint256 tokenBal = IERC20(token).balanceOf(address(this));

        uint256 protocolFeeAmount = tokenBal * protocolFee / feeDecimals;
        IERC20(token).safeTransfer(manager, protocolFeeAmount);

        uint256 fundManagerFeeAmount = tokenBal * fundManagerFee / feeDecimals;
        IERC20(token).safeTransfer(owner(), fundManagerFeeAmount);

        uint256 partnerFeeAmount = tokenBal * partnerFee / feeDecimals;
        IERC20(token).safeTransfer(partner, partnerFeeAmount);
    }

    function _lptoDepositTokenSwap(uint256 amount0, uint256 amount1) internal returns (uint256 totalDepositAsset) {
        uint256 amountOut;
        if (depositToken != lpToken0) {
            if (amount0 != 0) {amountOut = _swapV3In(lpToken0, depositToken, amount0, poolFee);}
            totalDepositAsset = amount1 + amountOut;
        }

        if (depositToken != lpToken1) {
            if (amount1 != 0) {amountOut = _swapV3In(lpToken1, depositToken, amount1, poolFee);}
            totalDepositAsset = amount0 + amountOut;
        }
    }

    function _setAddressArray(address[] storage strjArray, address[] memory memArray) internal {
        for (uint256 i = 0; i < memArray.length; i++) {
            strjArray.push(memArray[i]);
        }
    }

    function _setUint24Array(uint24[] storage strjArray, uint24[] memory memArray) internal {
        for (uint256 i = 0; i < memArray.length; i++) {
            strjArray.push(memArray[i]);
        }
    }

    // function getRewardToLp0Path() external view returns (address[] memory, uint24[] memory) {
    //     return (rewardToLp0AddressPath, rewardToLp0FeePath);
    // }

    // function getRewardToLp1Path() external view returns (address[] memory, uint24[] memory) {
    //     return (rewardToLp1AddressPath, rewardToLp1FeePath);
    // }

    function setRewardToLp0Path(address[] memory rewardToLp0AddressPath_, uint24[] memory rewardToLp0FeePath_) external {
        onlyManager();
        require(rewardToLp0FeePath_.length == rewardToLp0AddressPath_.length - 1, "IP");
        _setAddressArray(rewardToLp0AddressPath, rewardToLp0AddressPath_);
        _setUint24Array(rewardToLp0FeePath, rewardToLp0FeePath_);
        emit RewardToLp0PathChange(rewardToLp0AddressPath_, rewardToLp0FeePath_);
    }

    function setRewardToLp1Path(address[] memory rewardToLp1AddressPath_, uint24[] memory rewardToLp1FeePath_) external {
        onlyManager();
        require(rewardToLp1FeePath_.length == rewardToLp1AddressPath_.length - 1, "IP");
        _setAddressArray(rewardToLp1AddressPath, rewardToLp1AddressPath_);
        _setUint24Array(rewardToLp1FeePath, rewardToLp1FeePath_);
        emit RewardToLp1PathChange(rewardToLp1AddressPath_, rewardToLp1FeePath_);
    }

    // function setRewardtoNativeFeed(address rewardToNativeFeed_) external {
    //     onlyManager();
    //     require(rewardToNativeFeed_!=address(0), "IA");
    //     emit RewardToNativeFeedChange(rewardtoNativeFeed, rewardToNativeFeed_);
    //     rewardtoNativeFeed = rewardToNativeFeed_;
    // }

    // function setAssettoNativeFeed(address assettoNativeFeed_) external {
    //     onlyManager();
    //     require(assettoNativeFeed_!=address(0), "IA");
    //     emit AssetToNativeFeedChange(assettoNativeFeed, assettoNativeFeed_);
    //     assettoNativeFeed = assettoNativeFeed_;
    // }

    function _swapV3In(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 fee
    ) internal returns (uint256 amountOut) {
        amountOut = IV3SwapRouter(router).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                tokenIn,
                tokenOut,
                fee,
                address(this),
                amountIn,
                0,
                0
            )
        );
    }

    function _swapV3PathIn(
        address[] memory tokenPath,
        uint24[] memory feePath,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {

        bytes memory path = abi.encodePacked(tokenPath[0]);
        
        for (uint256 i = 0; i < feePath.length; i++) {
            path = abi.encodePacked(path, feePath[i], tokenPath[i+1]);
        }

        amountOut = IV3SwapRouter(router).exactInput(
            IV3SwapRouter.ExactInputParams(
                path,
                address(this),
                amountIn,
                0
            )
        );
    }

    function balanceOf() public view returns (uint256) {
        uint128 totalLiquidityDelta = liquidityBalance();
        (uint256 amount0, uint256 amount1) = DexV3Calculations.liquidityToAmounts(LiquidityToAmountCalcParams(tickLower, tickUpper, totalLiquidityDelta, safeCastLib, sqrtPriceMathLib, tickMathLib, stake));
        uint256 vaultReserve = IERC20(depositToken).balanceOf(vault);
        if (depositToken == lpToken0) {
            return amount0 + DexV3Calculations.convertAmount1ToAmount0(amount1, stake, fullMathLib) + vaultReserve;
        } else {
            return DexV3Calculations.convertAmount0ToAmount1(amount0, stake, fullMathLib) + amount1 + vaultReserve;
        }
    }

    function liquidityBalance() public view returns (uint128 liquidity) {
        if(tokenID==0){
            return 0;
        }else{
            (, , ,, ,,,  liquidity,,, ,  ) = INonfungiblePositionManager(NonfungiblePositionManager).positions(tokenID);
        }
    }

    function rewardsAvailable() public view returns (uint256 rewardsAvbl) {
        if(!hasFarm){
            return 0;
        }
        string memory signature = StringUtils.concat(
            pendingRewardsFunctionName,
            "(uint256)"
        );
        bytes memory result = Address.functionStaticCall(
            chef,
            abi.encodeWithSignature(signature, tokenID )
        );
        rewardsAvbl= abi.decode(result, (uint256));
    }

    function lpRewardsAvailable() public view returns (uint256 lpFeesDepositToken) {
        lpFeesDepositToken = DexV3Calculations.unclaimedFeesOfLpPosition(UnclaimedLpFeesParams(depositToken == lpToken0, tokenID, stake, NonfungiblePositionManager, fullMathLib));
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        onlyVault();
        (uint256 amount0, uint256 amount1) = _burnAndCollectV3();
        IERC20(depositToken).safeTransfer(vault, _lptoDepositTokenSwap(amount0, amount1));
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public {
        onlyManager();
        pause();
        (uint256 amount0, uint256 amount1) = _burnAndCollectV3();
        IERC20(depositToken).safeTransfer(vault, _lptoDepositTokenSwap(amount0, amount1));
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

        deposit();
    }

    function _giveAllowances() internal virtual {
        if(hasFarm){
        IERC20(reward).safeApprove(router, 0);
        IERC20(reward).safeApprove(router, type(uint256).max);
        }

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

    function _removeAllowances() internal virtual {
        if(hasFarm){
        IERC20(reward).safeApprove(router, 0);
        }
        IERC20(lpToken0).safeApprove(router, 0);
        IERC20(lpToken1).safeApprove(router, 0);
        IERC20(lpToken0).safeApprove(NonfungiblePositionManager, 0);
        IERC20(lpToken1).safeApprove(NonfungiblePositionManager, 0);
    }

}
