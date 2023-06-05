pragma solidity ^0.8.0;

import "./LendingBasedMarketNeutralCalculationsStruct.sol";
import "./DexV3CalculationStruct.sol";
import "./DexV3Calculations.sol";

import "@rivera/strategies/venus/interfaces/IVenusDistribution.sol";
import "@rivera/strategies/venus/interfaces/IVToken.sol";
import "@rivera/strategies/cake/interfaces/libraries/IFullMathLib.sol";


library LendingBasedMarketNeutralCalculations {
    function calculateLendingAmounts(LiquidityToAmountCalcParams calldata liquidityToAmountCalcParams, LendingParams calldata params) public returns (uint256, uint256) {
        (uint256 amount0, uint256 amount1) = DexV3Calculations.liquidityToAmounts(liquidityToAmountCalcParams);
        uint256 cMantissa;
        if (params.forDeposit) {
            (, uint256 collateralFactorMantissa, ) = IVenusDistribution(params.distribution).markets(params.vTokenDep);
            cMantissa = collateralFactorMantissa - params.safetyFactor;
        } else {
            uint256 totalBorrows = IVToken(params.vTokenNeu).borrowBalanceCurrent(params.strat);
            uint256 totalSupplies = IVToken(params.vTokenDep).balanceOfUnderlying(params.strat);
            cMantissa = IFullMathLib(params.fullMathLib).mulDiv(totalBorrows, params.MANTISSA, totalSupplies);
        }
        if (params.isToken0Deposit) {
            if (amount1 == 0) {
                return (0, 0);
            } else if (amount0 == 0) {
                return (params.amount, DexV3Calculations.convertAmount0ToAmount1(IFullMathLib(params.fullMathLib).mulDiv(params.amount, cMantissa, params.MANTISSA), liquidityToAmountCalcParams.poolAddress, params.fullMathLib));
            } else {
                uint256 denom = amount1 + IFullMathLib(params.fullMathLib).mulDiv(DexV3Calculations.convertAmount0ToAmount1(amount0, liquidityToAmountCalcParams.poolAddress, params.fullMathLib), cMantissa, params.MANTISSA);
                uint256 lendingDeposit = IFullMathLib(params.fullMathLib).mulDiv(params.amount, amount1, denom);
                return (lendingDeposit, DexV3Calculations.convertAmount0ToAmount1(IFullMathLib(params.fullMathLib).mulDiv(lendingDeposit, cMantissa, params.MANTISSA), liquidityToAmountCalcParams.poolAddress, params.fullMathLib));
            }
        } else {
            if (amount1 == 0) {
                return (params.amount, DexV3Calculations.convertAmount1ToAmount0(IFullMathLib(params.fullMathLib).mulDiv(params.amount, cMantissa, params.MANTISSA), liquidityToAmountCalcParams.poolAddress, params.fullMathLib));
            } else if (amount0 == 0) {
                return (0, 0);
            } else {
                uint256 denom = amount0 + IFullMathLib(params.fullMathLib).mulDiv(DexV3Calculations.convertAmount0ToAmount1(amount1, liquidityToAmountCalcParams.poolAddress, params.fullMathLib), cMantissa, params.MANTISSA);
                uint256 lendingDeposit = IFullMathLib(params.fullMathLib).mulDiv(params.amount, amount0, denom);
                return (lendingDeposit, DexV3Calculations.convertAmount1ToAmount0(IFullMathLib(params.fullMathLib).mulDiv(lendingDeposit, cMantissa, params.MANTISSA), liquidityToAmountCalcParams.poolAddress, params.fullMathLib));
            }
        }
    }

}