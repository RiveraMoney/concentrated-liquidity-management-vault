pragma solidity >=0.5.0;

struct CreateVaultParams {
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
}

enum VaultType {
        PRIVATE ,
        PUBLIC,
        WHITELISTED
    }

interface IRiveraAutoCompoundingVaultFactoryV2 {
    event VaultCreated(address indexed user, address indexed stake, address vault);

    function allVaults(uint) external view returns (address vault);
    function createVault(CreateVaultParams memory createVaultParams,VaultType _vaultType) external returns (address vault);

}
