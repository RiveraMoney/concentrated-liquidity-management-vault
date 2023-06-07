pragma solidity ^0.8.0;

import "@pancakeswap-v3-core/interfaces/IPancakeV3Pool.sol";
import "@pancakeswap-v3-core/libraries/FixedPoint96.sol";
import "@pancakeswap-v3-core/libraries/FixedPoint128.sol";
import "@rivera/strategies/cake/interfaces/INonfungiblePositionManager.sol";

import "@rivera/strategies/cake/interfaces/libraries/ITickMathLib.sol";
import "@rivera/strategies/cake/interfaces/libraries/ISqrtPriceMathLib.sol";
import "@rivera/strategies/cake/interfaces/libraries/ILiquidityMathLib.sol";
import "@rivera/strategies/cake/interfaces/libraries/ISafeCastLib.sol";
import "@rivera/strategies/cake/interfaces/libraries/ILiquidityAmountsLib.sol";
import "@rivera/strategies/cake/interfaces/libraries/IFullMathLib.sol";

import "@rivera/libs/DexV3CalculationStruct.sol";


library DexV3Calculations {

    function liquidityToAmounts(LiquidityToAmountCalcParams calldata liquidityToAmountCalcParams) public view returns (uint256 amount0, uint256 amount1) {
        IPancakeV3Pool pool = IPancakeV3Pool(liquidityToAmountCalcParams.poolAddress);
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        int128 liquidityDeltaInt = ISafeCastLib(liquidityToAmountCalcParams.safeCastLib).toInt128(ISafeCastLib(liquidityToAmountCalcParams.safeCastLib).toInt256(uint256(liquidityToAmountCalcParams.liquidityDelta)));
        if (tick < liquidityToAmountCalcParams.tickLower) {
            amount0 = uint256(ISqrtPriceMathLib(liquidityToAmountCalcParams.sqrtPriceMathLib).getAmount0Delta(
                ITickMathLib(liquidityToAmountCalcParams.tickMathLib).getSqrtRatioAtTick(liquidityToAmountCalcParams.tickLower),
                ITickMathLib(liquidityToAmountCalcParams.tickMathLib).getSqrtRatioAtTick(liquidityToAmountCalcParams.tickUpper),
                liquidityDeltaInt
            ));
        } else if (tick < liquidityToAmountCalcParams.tickUpper) {
            amount0 = uint256(ISqrtPriceMathLib(liquidityToAmountCalcParams.sqrtPriceMathLib).getAmount0Delta(
                sqrtPriceX96,
                ITickMathLib(liquidityToAmountCalcParams.tickMathLib).getSqrtRatioAtTick(liquidityToAmountCalcParams.tickUpper),
                liquidityDeltaInt
            ));
            amount1 = uint256(ISqrtPriceMathLib(liquidityToAmountCalcParams.sqrtPriceMathLib).getAmount1Delta(
                ITickMathLib(liquidityToAmountCalcParams.tickMathLib).getSqrtRatioAtTick(liquidityToAmountCalcParams.tickLower),
                sqrtPriceX96,
                liquidityDeltaInt
            ));
        } else {
            amount1 = uint256(ISqrtPriceMathLib(liquidityToAmountCalcParams.sqrtPriceMathLib).getAmount1Delta(
                ITickMathLib(liquidityToAmountCalcParams.tickMathLib).getSqrtRatioAtTick(liquidityToAmountCalcParams.tickLower),
                ITickMathLib(liquidityToAmountCalcParams.tickMathLib).getSqrtRatioAtTick(liquidityToAmountCalcParams.tickUpper),
                liquidityDeltaInt
            ));
        }

    }

    /// @dev Common checks for valid tick inputs. From Uniswap V3 pool
    function checkTicks(int24 tickLower, int24 tickUpper, int24 tickLower_, int24 tickUpper_, address tickMathLib, address pool) public view {
        require(!(tickLower == tickLower_ && tickUpper == tickUpper_), "SR");
        require(tickLower_ < tickUpper_, "TOI");
        require(tickLower_ >= ITickMathLib(tickMathLib).MIN_TICK(), "LTTL");
        require(tickUpper_ <= ITickMathLib(tickMathLib).MAX_TICK(), "UTTH");
        int24 tickSpacing = IPancakeV3Pool(pool).tickSpacing();
        require(tickLower_ % tickSpacing == 0 && tickUpper_ % tickSpacing == 0, "IT");
    }

    function convertAmount0ToAmount1(uint256 amount0, address pool, address fullMathLib) public view returns (uint256 amount1) {
        (uint160 sqrtPriceX96, , , , , , ) = IPancakeV3Pool(pool).slot0();
        amount1 = IFullMathLib(fullMathLib).mulDiv(IFullMathLib(fullMathLib).mulDiv(amount0, sqrtPriceX96, FixedPoint96.Q96), sqrtPriceX96, FixedPoint96.Q96);
    }

    function convertAmount1ToAmount0(uint256 amount1, address pool, address fullMathLib) public view returns (uint256 amount0) {
        (uint160 sqrtPriceX96, , , , , , ) = IPancakeV3Pool(pool).slot0();
        amount0 = IFullMathLib(fullMathLib).mulDiv(IFullMathLib(fullMathLib).mulDiv(amount1, FixedPoint96.Q96, sqrtPriceX96), FixedPoint96.Q96, sqrtPriceX96);
    }

    function calculateLiquidityDeltaForAssetAmount(LiquidityToAmountCalcParams calldata liquidityToAmountCalcParams, LiquidityDeltaForAssetAmountParams calldata liquidityDeltaForAssetAmountParams) public view returns (uint128 liquidityDelta) {
        (uint256 token0Ratio, uint256 token1Ratio) = liquidityToAmounts(liquidityToAmountCalcParams);
        uint256 amount0; uint256 amount1;
        if (liquidityDeltaForAssetAmountParams.isTokenZeroDeposit) {
            amount1 = IFullMathLib(liquidityDeltaForAssetAmountParams.fullMathLib).mulDiv(liquidityDeltaForAssetAmountParams.assetAmount, token1Ratio, token0Ratio + convertAmount1ToAmount0(token1Ratio - token1Ratio * liquidityDeltaForAssetAmountParams.poolFee / 1e6, liquidityToAmountCalcParams.poolAddress, liquidityDeltaForAssetAmountParams.fullMathLib));
            amount0 = liquidityDeltaForAssetAmountParams.assetAmount - convertAmount1ToAmount0(amount1 - amount1 * liquidityDeltaForAssetAmountParams.poolFee / 1e6, liquidityToAmountCalcParams.poolAddress, liquidityDeltaForAssetAmountParams.fullMathLib);
        } else {
            amount0 = IFullMathLib(liquidityDeltaForAssetAmountParams.fullMathLib).mulDiv(liquidityDeltaForAssetAmountParams.assetAmount, token0Ratio, token1Ratio + convertAmount0ToAmount1(token0Ratio - token0Ratio * liquidityDeltaForAssetAmountParams.poolFee / 1e6, liquidityToAmountCalcParams.poolAddress, liquidityDeltaForAssetAmountParams.fullMathLib));
            amount1 = liquidityDeltaForAssetAmountParams.assetAmount - convertAmount0ToAmount1(amount0 - amount0 * liquidityDeltaForAssetAmountParams.poolFee / 1e6, liquidityToAmountCalcParams.poolAddress, liquidityDeltaForAssetAmountParams.fullMathLib);
        }
        IPancakeV3Pool pool = IPancakeV3Pool(liquidityToAmountCalcParams.poolAddress);
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        if (tick < liquidityToAmountCalcParams.tickLower) {
            liquidityDelta = ILiquidityAmountsLib(liquidityDeltaForAssetAmountParams.liquidityAmountsLib).getLiquidityForAmount0(ITickMathLib(liquidityToAmountCalcParams.tickMathLib).getSqrtRatioAtTick(liquidityToAmountCalcParams.tickLower),
                ITickMathLib(liquidityToAmountCalcParams.tickMathLib).getSqrtRatioAtTick(liquidityToAmountCalcParams.tickUpper), amount0);  
        } else if (tick < liquidityToAmountCalcParams.tickUpper) {
            liquidityDelta = ILiquidityAmountsLib(liquidityDeltaForAssetAmountParams.liquidityAmountsLib).getLiquidityForAmount0(sqrtPriceX96,
                ITickMathLib(liquidityToAmountCalcParams.tickMathLib).getSqrtRatioAtTick(liquidityToAmountCalcParams.tickUpper), amount0);
        } else {
            liquidityDelta = ILiquidityAmountsLib(liquidityDeltaForAssetAmountParams.liquidityAmountsLib).getLiquidityForAmount1(ITickMathLib(liquidityToAmountCalcParams.tickMathLib).getSqrtRatioAtTick(liquidityToAmountCalcParams.tickLower),
                ITickMathLib(liquidityToAmountCalcParams.tickMathLib).getSqrtRatioAtTick(liquidityToAmountCalcParams.tickUpper), convertAmount0ToAmount1(amount1, liquidityToAmountCalcParams.poolAddress, liquidityDeltaForAssetAmountParams.fullMathLib));
        }
    }

    function changeInAmountsToNewRangeRatio(LiquidityToAmountCalcParams calldata liquidityToAmountCalcParams, ChangeInAmountsForNewRatioParams calldata changeInAmountsForNewRatioParams) public view returns (uint256 x, uint256 y) {
        require(!(changeInAmountsForNewRatioParams.currAmount0Bal==0 && changeInAmountsForNewRatioParams.currAmount1Bal==0), "NA");
        (uint256 amount0, uint256 amount1) = liquidityToAmounts(liquidityToAmountCalcParams);
        if (amount0 == 0) {
            x = changeInAmountsForNewRatioParams.currAmount0Bal;
        } else if (amount1 == 0) {
            y = changeInAmountsForNewRatioParams.currAmount1Bal;
        } else {
            if (changeInAmountsForNewRatioParams.currAmount0Bal > changeInAmountsForNewRatioParams.currAmount1Bal) { //This check is to make sure the ratio doesn't get 0 when checking which ratio is greater
                if (changeInAmountsForNewRatioParams.currAmount1Bal==0) {
                    x = IFullMathLib(changeInAmountsForNewRatioParams.fullMathLib).mulDiv(amount1, changeInAmountsForNewRatioParams.currAmount0Bal, convertAmount0ToAmount1(amount0, liquidityToAmountCalcParams.poolAddress, changeInAmountsForNewRatioParams.fullMathLib) + amount1 + amount1*changeInAmountsForNewRatioParams.poolFee/1e6);
                } else {
                    if (changeInAmountsForNewRatioParams.currAmount0Bal / changeInAmountsForNewRatioParams.currAmount1Bal > amount0 / amount1) {
                        x = IFullMathLib(changeInAmountsForNewRatioParams.fullMathLib).mulDiv(amount1, changeInAmountsForNewRatioParams.currAmount0Bal, convertAmount0ToAmount1(amount0, liquidityToAmountCalcParams.poolAddress, changeInAmountsForNewRatioParams.fullMathLib) + amount1 + amount1*changeInAmountsForNewRatioParams.poolFee/1e6) - 
                        IFullMathLib(changeInAmountsForNewRatioParams.fullMathLib).mulDiv(amount0, changeInAmountsForNewRatioParams.currAmount1Bal, convertAmount0ToAmount1(amount0, liquidityToAmountCalcParams.poolAddress, changeInAmountsForNewRatioParams.fullMathLib) + amount1 + amount1*changeInAmountsForNewRatioParams.poolFee/1e6);
                    } else {
                        y = IFullMathLib(changeInAmountsForNewRatioParams.fullMathLib).mulDiv(amount0, changeInAmountsForNewRatioParams.currAmount1Bal, convertAmount1ToAmount0(amount1, liquidityToAmountCalcParams.poolAddress, changeInAmountsForNewRatioParams.fullMathLib) + amount0 + amount0*changeInAmountsForNewRatioParams.poolFee/1e6) - 
                        IFullMathLib(changeInAmountsForNewRatioParams.fullMathLib).mulDiv(amount1, changeInAmountsForNewRatioParams.currAmount0Bal, convertAmount1ToAmount0(amount1, liquidityToAmountCalcParams.poolAddress, changeInAmountsForNewRatioParams.fullMathLib) + amount0 + amount0*changeInAmountsForNewRatioParams.poolFee/1e6);
                    }
                }
            } else {
                if (changeInAmountsForNewRatioParams.currAmount0Bal == 0) {
                    y = IFullMathLib(changeInAmountsForNewRatioParams.fullMathLib).mulDiv(amount0, changeInAmountsForNewRatioParams.currAmount1Bal, convertAmount1ToAmount0(amount1, liquidityToAmountCalcParams.poolAddress, changeInAmountsForNewRatioParams.fullMathLib) + amount0 + amount0*changeInAmountsForNewRatioParams.poolFee/1e6);
                } else {
                    if (changeInAmountsForNewRatioParams.currAmount1Bal / changeInAmountsForNewRatioParams.currAmount0Bal > amount1 / amount0) {
                        y = IFullMathLib(changeInAmountsForNewRatioParams.fullMathLib).mulDiv(amount0, changeInAmountsForNewRatioParams.currAmount1Bal, convertAmount1ToAmount0(amount1, liquidityToAmountCalcParams.poolAddress, changeInAmountsForNewRatioParams.fullMathLib) + amount0 + amount0*changeInAmountsForNewRatioParams.poolFee/1e6) - 
                        IFullMathLib(changeInAmountsForNewRatioParams.fullMathLib).mulDiv(amount1, changeInAmountsForNewRatioParams.currAmount0Bal, convertAmount1ToAmount0(amount1, liquidityToAmountCalcParams.poolAddress, changeInAmountsForNewRatioParams.fullMathLib) + amount0 + amount0*changeInAmountsForNewRatioParams.poolFee/1e6);
                    } else {
                        x = IFullMathLib(changeInAmountsForNewRatioParams.fullMathLib).mulDiv(amount1, changeInAmountsForNewRatioParams.currAmount0Bal, convertAmount0ToAmount1(amount0, liquidityToAmountCalcParams.poolAddress, changeInAmountsForNewRatioParams.fullMathLib) + amount1 + amount1*changeInAmountsForNewRatioParams.poolFee/1e6) - 
                        IFullMathLib(changeInAmountsForNewRatioParams.fullMathLib).mulDiv(amount0, changeInAmountsForNewRatioParams.currAmount1Bal, convertAmount0ToAmount1(amount0, liquidityToAmountCalcParams.poolAddress, changeInAmountsForNewRatioParams.fullMathLib) + amount1 + amount1*changeInAmountsForNewRatioParams.poolFee/1e6);
                    }
                }
            }
        }
    }

    struct UnclaimedFeeCalcInfo {
        int24 tickLower;
        int24 tickUpper;
        int24 tickCurrent;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint256 feeGrowthGlobal0;
        uint256 feeGrowthGlobal1;
        uint256 feeGrowthOutside0X128Lower;
        uint256 feeGrowthOutside1X128Lower;
        uint256 feeGrowthOutside0X128Upper;
        uint256 feeGrowthOutside1X128Upper;
    }

    function unclaimedFeesOfLpPosition(UnclaimedLpFeesParams calldata params) public view returns (uint256, uint256) {
        UnclaimedFeeCalcInfo memory unclFeeInfo;
        ( , , , , , unclFeeInfo.tickLower, unclFeeInfo.tickUpper, unclFeeInfo.liquidity, unclFeeInfo.feeGrowthInside0LastX128,
            unclFeeInfo.feeGrowthInside1LastX128, , ) = INonfungiblePositionManager(params.nonFungiblePositionManger).positions(params.tokenId);
        ( , int24 tickCurrent, , , , , ) = IPancakeV3Pool(params.poolAddress).slot0();
        unclFeeInfo.feeGrowthGlobal0 = IPancakeV3Pool(params.poolAddress).feeGrowthGlobal0X128();
	    unclFeeInfo.feeGrowthGlobal1 = IPancakeV3Pool(params.poolAddress).feeGrowthGlobal1X128();
        ( , , unclFeeInfo.feeGrowthOutside0X128Lower, unclFeeInfo.feeGrowthOutside1X128Lower, , , , ) = IPancakeV3Pool(params.poolAddress).ticks(unclFeeInfo.tickLower);
        ( , , unclFeeInfo.feeGrowthOutside0X128Upper, unclFeeInfo.feeGrowthOutside1X128Upper, , , , ) = IPancakeV3Pool(params.poolAddress).ticks(unclFeeInfo.tickUpper);

        uint256 tickUpperFeeGrowthAbove_0; uint256 tickUpperFeeGrowthAbove_1;
        if (tickCurrent >= unclFeeInfo.tickUpper){
            tickUpperFeeGrowthAbove_0 = unclFeeInfo.feeGrowthGlobal0 - unclFeeInfo.feeGrowthOutside0X128Upper;
            tickUpperFeeGrowthAbove_1 = unclFeeInfo.feeGrowthGlobal1 - unclFeeInfo.feeGrowthOutside1X128Upper;
        } else{
            tickUpperFeeGrowthAbove_0 = unclFeeInfo.feeGrowthOutside0X128Upper;
            tickUpperFeeGrowthAbove_1 = unclFeeInfo.feeGrowthOutside1X128Upper;
        }

        uint256 tickLowerFeeGrowthBelow_0; uint256 tickLowerFeeGrowthBelow_1;
        if (tickCurrent >= unclFeeInfo.tickLower){
            tickLowerFeeGrowthBelow_0 = unclFeeInfo.feeGrowthOutside0X128Lower;
            tickLowerFeeGrowthBelow_1 = unclFeeInfo.feeGrowthOutside1X128Lower;
        } else{
            tickLowerFeeGrowthBelow_0 = unclFeeInfo.feeGrowthGlobal0 - unclFeeInfo.feeGrowthOutside0X128Lower;
            tickLowerFeeGrowthBelow_1 = unclFeeInfo.feeGrowthGlobal1 - unclFeeInfo.feeGrowthOutside1X128Lower;
        }
        
        return (IFullMathLib(params.fullMathLib).mulDiv(unclFeeInfo.liquidity, (unclFeeInfo.feeGrowthGlobal0 - tickLowerFeeGrowthBelow_0 - tickUpperFeeGrowthAbove_0) - unclFeeInfo.feeGrowthInside0LastX128, FixedPoint128.Q128), 
        IFullMathLib(params.fullMathLib).mulDiv(unclFeeInfo.liquidity, (unclFeeInfo.feeGrowthGlobal1 - tickLowerFeeGrowthBelow_1 - tickUpperFeeGrowthAbove_1) - unclFeeInfo.feeGrowthInside1LastX128, FixedPoint128.Q128));
        
    }

}