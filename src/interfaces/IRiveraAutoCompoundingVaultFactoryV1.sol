pragma solidity >=0.5.0;

struct CreateVaultParams {
    address lpPool;
    uint256 poolId;
    address[] rewardToLp0Route;
    address[] rewardToLp1Route;
    string tokenName;
    string tokenSymbol;
}

interface IRiveraAutoCompoundingVaultFactoryV1 {
    event VaultCreated(address indexed user, address indexed lpPool, uint256 indexed poolId, address vault);

    function getVault(address user, address lpPool, uint256 poolId) external view returns (address vault);
    function allVaults(uint) external view returns (address vault);
    function allVaultsLength() external view returns (uint);
    function createVault(CreateVaultParams memory createVaultParams) external returns (address vault);

}
