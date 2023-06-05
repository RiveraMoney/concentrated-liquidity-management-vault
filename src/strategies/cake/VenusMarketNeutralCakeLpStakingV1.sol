pragma solidity ^0.8.0;

import "./CakeLpStakingV2.sol";
import "@rivera/strategies/venus/interfaces/IVenusDistribution.sol";
import "@rivera/libs/LendingBasedMarketNeutralCalculations.sol";
import "@rivera/strategies/venus/interfaces/IVToken.sol";

contract VenusMarketNeutralCakeLpStakingV1 is CakeLpStakingV2 {
    using SafeERC20 for IERC20;

    uint256 public safetyFactor;        //Represented in mantissa ie scaled up by 1e18
    uint256 public immutable MANTISSA = 1e18;
    address public vToken0;
    address public vToken1;
    address public distribution;

    event StratRebalance(address caller, uint256 tvl);

    function init(CakePoolParams memory _cakePoolParams, CommonAddresses memory _commonAddresses, uint256 safetyFactor_, address vToken0_, address vToken1_, address distribution_) public initializer {
        safetyFactor = safetyFactor_;
        vToken0 = vToken0_;
        vToken1 = vToken1_;
        distribution = distribution_;
        address[] memory vTokens = new address[](2);
        vTokens[0] = vToken0;
        vTokens[1] = vToken1;
        IVenusDistribution(distribution).enterMarkets(vTokens);
        super.init(_cakePoolParams, _commonAddresses);
    }

    function getDepositvToken() public view returns (address) {
        return isTokenZeroDeposit? vToken0: vToken1;
    }

    function getNeutralvToken() public view returns (address) {
        return isTokenZeroDeposit? vToken1: vToken0;
    }

    function getNeutralToken() public view returns (address) {
        return isTokenZeroDeposit? lpToken1: lpToken0;
    }

    function _deposit() internal override virtual {
        uint256 amount = IERC20(getDepositToken()).balanceOf(address(this));
        (uint256 lendDep, uint256 lendBorrow) = LendingBasedMarketNeutralCalculations.calculateLendingAmounts(LiquidityToAmountCalcParams(tickLower, tickUpper, 1e28, safeCastLib, 
        sqrtPriceMathLib, tickMathLib, stake), LendingParams(isTokenZeroDeposit, true, amount, safetyFactor, MANTISSA, fullMathLib, getDepositvToken(), getNeutralvToken(), distribution, address(this)));
        if (lendDep != 0) {
            IVToken(getDepositvToken()).mint(lendDep);
            IVToken(getNeutralvToken()).borrow(lendBorrow);
        }
        depositV3();
    }

    function withdraw(uint256 amount) public override virtual {
        onlyVault();
        (uint256 lendWithdraw, uint256 lendRepay) = LendingBasedMarketNeutralCalculations.calculateLendingAmounts(LiquidityToAmountCalcParams(tickLower, tickUpper, 1e28, safeCastLib, 
        sqrtPriceMathLib, tickMathLib, stake), LendingParams(isTokenZeroDeposit, false, amount, safetyFactor, MANTISSA, fullMathLib, getDepositvToken(), getNeutralvToken(), distribution, address(this)));
        uint256 assetBalBef = IERC20(getDepositToken()).balanceOf(address(this));
        _withdrawV3(amount - lendWithdraw);
        _lendingRepayAndWithdraw(lendRepay, lendWithdraw);
        IERC20(getDepositToken()).safeTransfer(vault, IERC20(getDepositToken()).balanceOf(address(this)) - assetBalBef);
        emit Withdraw(balanceOf(), amount);
    }

    function _swapV3Out(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint24 fee
    ) internal returns (uint256 amountIn) {
        amountIn = IV3SwapRouter(router).exactOutputSingle(
            IV3SwapRouter.ExactOutputSingleParams(
                tokenIn,
                tokenOut,
                fee,
                address(this),
                amountOut,
                type(uint256).max,
                0
            )
        );
    }

    function _lendingRepayAndWithdraw(uint256 lendRepay, uint256 lendWithdraw) internal {
        uint256 currBal = IERC20(getNeutralToken()).balanceOf(address(this));
        if (currBal < lendRepay) {
            _swapV3Out(getDepositToken(), getNeutralToken(), lendRepay - currBal, poolFee);
        }
        if (lendWithdraw != 0) {
            IVToken(getNeutralvToken()).repayBorrow(lendRepay);
            IVToken(getDepositvToken()).redeemUnderlying(lendWithdraw);
        }
    }

    function changeRange(int24 _tickLower, int24 _tickUpper) external override virtual {
        _checkOwner();
        require(!(tickLower == _tickLower && tickUpper == _tickUpper), "SR");
        DexV3Calculations.checkTicks(_tickLower, _tickUpper, tickMathLib, stake);
        _burnAndCollectV3();        //This will return token0 and token1 in a ratio that is corresponding to the current range not the one we're setting it to
        uint256 totalBorrows = IVToken(getNeutralToken()).borrowBalanceCurrent(address(this));
        uint256 totalSupplies = IVToken(getDepositToken()).balanceOfUnderlying(address(this));
        _lendingRepayAndWithdraw(totalBorrows, totalSupplies);
        tickLower = _tickLower;
        tickUpper = _tickUpper;
        _deposit();
        emit RangeChange(tickLower, tickUpper);
    }

    function harvest() external override virtual {
        _requireNotPaused();
        IMasterChefV3(chef).harvest(tokenID, address(this));
        uint256 rewardBal = IERC20(reward).balanceOf(address(this));
        if (rewardBal > 0) {
            if (lpToken0 != reward && isTokenZeroDeposit) {
                _swapV3PathIn(rewardToLp0AddressPath, rewardToLp0FeePath, rewardBal);
            }

            if (lpToken1 != reward && !isTokenZeroDeposit) {
                _swapV3PathIn(rewardToLp1AddressPath, rewardToLp1FeePath, rewardBal);
            }

            lastHarvest = block.timestamp;
        }
        (uint256 amount0, uint256 amount1) = IMasterChefV3(chef).collect(
            INonfungiblePositionManager.CollectParams(
                tokenID,
                address(this),
                type(uint128).max,
                type(uint128).max
            )
        );
        _lptoDepositTokenSwap(amount0, amount1);
        _deposit();
        emit StratHarvest(
                msg.sender,
                rewardBal,
                balanceOf()
            );
    }

    function rebalance() external virtual {
        _requireNotPaused();
        _burnAndCollectV3();
        uint256 totalBorrows = IVToken(getNeutralToken()).borrowBalanceCurrent(address(this));
        uint256 totalSupplies = IVToken(getDepositToken()).balanceOfUnderlying(address(this));
        _lendingRepayAndWithdraw(totalBorrows, totalSupplies);
        _deposit();
        emit StratRebalance(msg.sender, balanceOf());
    }

    function _giveAllowances() internal virtual override {

        IERC20(lpToken0).safeApprove(vToken0, 0);
        IERC20(lpToken0).safeApprove(vToken0, type(uint256).max);

        IERC20(lpToken1).safeApprove(vToken1, 0);
        IERC20(lpToken1).safeApprove(vToken1, type(uint256).max);

        super._giveAllowances();

    }

    function _removeAllowances() internal virtual override {
        IERC20(lpToken0).safeApprove(vToken0, 0);
        IERC20(lpToken1).safeApprove(vToken1, 0);
        super._removeAllowances();
    }
}