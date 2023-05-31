pragma solidity ^0.8.0;

import './interfaces/IRiveraAutoCompoundingVaultFactoryV2.sol';
import './strategies/common/interfaces/IStrategy.sol';
import './vaults/RiveraAutoCompoundingVaultV2Public.sol';
import './PancakeStratFactoryV2.sol';

contract PancakeVaultFactoryV2 is IRiveraAutoCompoundingVaultFactoryV2 {

    address[] public allVaults;

    ///@notice fixed params that are required to deploy the pool
    address chef;
    address router;
    address NonfungiblePositionManager;
    address manager;
    address stratFactory;
    VaultType immutable vaultType = VaultType.PUBLIC;

    constructor(address _chef, address _router, address _NonfungiblePositionManager, address _stratFactory) {
        chef = _chef;
        router = _router;
        NonfungiblePositionManager = _NonfungiblePositionManager;
        stratFactory = _stratFactory;
        manager = msg.sender;
    }

    function createVault(CreateVaultParams memory createVaultParams) external returns (address vaultAddress) {
        RiveraAutoCompoundingVaultV2Public vault = new RiveraAutoCompoundingVaultV2Public(createVaultParams.asset, createVaultParams.tokenName, createVaultParams.tokenSymbol, 
        createVaultParams.approvalDelay, createVaultParams.totalTvlCap);
        vaultAddress = address(vault);
        address stratAddress = PancakeStratFactoryV2(stratFactory).createStrat(createVaultParams, vaultAddress, msg.sender, manager, router, NonfungiblePositionManager, chef);
        vault.transferOwnership(msg.sender);
        vault.init(IStrategy(stratAddress));
        allVaults.push(vaultAddress);
        emit VaultCreated(msg.sender, createVaultParams.stake,  vaultAddress);
    }

    function listAllVaults() external view returns (address[] memory) {
        return allVaults;
    }

}
