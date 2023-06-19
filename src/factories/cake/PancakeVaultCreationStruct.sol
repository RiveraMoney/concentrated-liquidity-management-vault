pragma solidity >=0.5.0;

struct PancakeVaultParams {
    address asset;
    uint256 totalTvlCap;
    uint256 approvalDelay;
    string tokenName;
    string tokenSymbol;
    int24 tickLower;
    int24 tickUpper;
    address stake;
    address[] rewardToLp0AddressPath;
    uint24[] rewardToLp0FeePath;
    address[] rewardToLp1AddressPath;
    uint24[] rewardToLp1FeePath;
    address  rewardtoNativeFeed;
    address  assettoNativeFeed;
    address tickMathLib;
    address sqrtPriceMathLib;
    address liquidityMathLib;
    address safeCastLib;
    address liquidityAmountsLib;
    address fullMathLib;
    string pendingReward;
}

struct VenusMarketNeutralParams {
    uint256 safetyFactor_; 
    address vToken0_; 
    address vToken1_; 
    address distribution_;
}