//  SPDX-License-Identifier: UNLICENSED
 pragma solidity 0.7.6;

 import "forge-std/Script.sol";
 import "forge-std/console2.sol";
 import "@rivera/interfaces/IPancakeV3PoolState.sol";
 import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
 import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
 import '@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol';
 import '@uniswap/v3-core/contracts/libraries/LiquidityMath.sol';
 import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
 import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

 contract AssetRatioCalculator is Script {

    using SafeCast for int256;

     address _pool = 0x2dA32920A775CF121004551AbC92F385B3C0Dab9;
     uint16 constant N = 16;
     int24[N] _tickLower = [int24(-5000), int24(-2500), int24(0), int24(2500), int24(5000), int24(7500), int24(10000), int24(12500), int24(15000), int24(17500), int24(20000), int24(22500), int24(25000), int24(27500), int24(30000), int24(32500)];
     int24[N] _tickUpper = [int24(5000), int24(7500), int24(10000), int24(12500), int24(15000), int24(17500), int24(20000), int24(22500), int24(25000), int24(27500), int24(30000), int24(32500), int24(35000), int24(37500), int24(40000), int24(42500)];


     function assetRatio(int24 tickLower, int24 tickUpper) public view returns (uint256 amount0, uint256 amount1) {
        IUniswapV3Pool pool = IUniswapV3Pool(_pool);
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                1e22,
                1e22
            );      //We're simply defaulting amount0 desired and amount1 desired to 1 because we only care about the ratio of assets. Uniswap library will automatically figure out the limitting asset and give us the ratio.

        int256 amount0Int; int256 amount1Int;
        if (liquidity != 0) {
            if (tick < tickLower) {
                // current tick is below the passed range; liquidity can only become in range by crossing from left to
                // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
                amount0Int = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    int256(liquidity).toInt128()
                );
            } else if (tick < tickUpper) {
                // current tick is inside the passed range
                uint128 liquidityBefore = liquidity; // SLOAD for gas optimization

                amount0Int = SqrtPriceMath.getAmount0Delta(
                    sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    int256(liquidity).toInt128()
                );
                amount1Int = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    sqrtPriceX96,
                    int256(liquidity).toInt128()
                );

            } else {
                // current tick is above the passed range; liquidity can only become in range by crossing from right to
                // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
                amount1Int = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    int256(liquidity).toInt128()
                );
            }
        }
        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int);
     }

     function run() external view {
        int24[N] memory tickLower = _tickLower;
        int24[N] memory tickUpper = _tickUpper;
        for (uint256 i = 0; i < N; i++) {
            console2.logString("Lower Tick: ");
            console2.logInt(tickLower[i]);
            console2.logString("Upper Tick: ");
            console2.logInt(tickUpper[i]);
            (uint256 amount0, uint256 amount1) = assetRatio(tickLower[i], tickUpper[i]);
            console2.logString("Amount 0: ");
            console2.logUint(amount0);
            console2.logString("Amount 1: ");
            console2.logUint(amount1);
        }
     }
 }