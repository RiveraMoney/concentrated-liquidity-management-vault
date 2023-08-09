pragma solidity ^0.8.0;

struct LiquidityToAmountCalcParams {
    int24 tickLower;
    int24 tickUpper;
    uint128 liquidityDelta;
    address safeCastLib;
    address sqrtPriceMathLib;
    address tickMathLib;
    address poolAddress;
}

struct LiquidityDeltaForAssetAmountParams {
    bool isTokenZeroDeposit;
    uint24 poolFee;
    uint256 assetAmount;
    address fullMathLib;
    address liquidityAmountsLib;
}

struct ChangeInAmountsForNewRatioParams {
    uint24 poolFee;
    uint256 currAmount0Bal;
    uint256 currAmount1Bal;
    address fullMathLib;
    address liquidityAmountsLib;
}

struct UnclaimedLpFeesParams {
    bool isToken0Deposit;
    uint256 tokenId; 
    address poolAddress; 
    address nonFungiblePositionManger; 
    address fullMathLib; 
}