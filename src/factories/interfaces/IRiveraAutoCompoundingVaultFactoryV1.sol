pragma solidity >=0.5.0;

struct CreateVaultParams {
    uint256 poolId;
    uint256 approvalDelay;
    address[] rewardToLp0Route;
    address[] rewardToLp1Route;
    string tokenName;
    string tokenSymbol;
    string pendingRewardsFunctionName;
}

interface IRiveraAutoCompoundingVaultFactoryV1 {
    event VaultCreated(address indexed user, address indexed lpPool, uint256 indexed poolId, address vault);

    function allVaults(uint) external view returns (address vault);
    function createVault(CreateVaultParams memory createVaultParams) external returns (address vault);

}
