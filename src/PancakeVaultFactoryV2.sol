pragma solidity ^0.8.0;

import './interfaces/IRiveraAutoCompoundingVaultFactoryV2.sol';
import './strategies/common/interfaces/IStrategy.sol';
// import './vaults/RiveraAutoCompoundingVaultV2.sol';
import './vaults/RiveraAutoCompoundingVaultV2Private.sol';
import './vaults/RiveraAutoCompoundingVaultV2Public.sol';
import './vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol';
import './strategies/cake/CakeLpStakingV2.sol';



contract PancakeVaultFactoryV2 is IRiveraAutoCompoundingVaultFactoryV2 {

    address[] public allVaults;

    ///@notice fixed params that are required to deploy the pool
    address chef;
    address router;
    address NonfungiblePositionManager;
    address manager;

    constructor(address _chef, address _router, address _NonfungiblePositionManager) {
        chef = _chef;
        router = _router;
        NonfungiblePositionManager = _NonfungiblePositionManager;
        manager = msg.sender;
    }

    function createVault(CreateVaultParams memory createVaultParams,VaultType _vaultType ) external returns (address vaultAddress) {
        address reward= createVaultParams.rewardToLp0AddressPath[0];
        
        CakeLpStakingV2 strategy;
        if(_vaultType == VaultType.PUBLIC){
            //create public vault
            RiveraAutoCompoundingVaultV2Public vault = new RiveraAutoCompoundingVaultV2Public(createVaultParams.asset,createVaultParams.tokenName, createVaultParams.tokenSymbol, createVaultParams.approvalDelay,createVaultParams.totalTvlCap);
            vaultAddress = address(vault);
            // strategy = new CakeLpStakingV2(CakePoolParams(createVaultParams.tickLower,createVaultParams.tickUpper,createVaultParams.stake,chef,reward,createVaultParams.tickMathLib,createVaultParams.sqrtPriceMathLib,createVaultParams.liquidityMathLib,createVaultParams.safeCastLib,createVaultParams.liquidityAmountsLib,createVaultParams.fullMathLib,createVaultParams.rewardToLp0AddressPath,createVaultParams.rewardToLp0FeePath,createVaultParams.rewardToLp1AddressPath,createVaultParams.rewardToLp1FeePath ,createVaultParams.rewardtoNativeFeed,createVaultParams.assettoNativeFeed),
            //                                             CommonAddresses(vaultAddress, router,NonfungiblePositionManager));
            strategy=_createStrategy(CakePoolParams(createVaultParams.tickLower,createVaultParams.tickUpper,createVaultParams.stake,chef,reward,createVaultParams.tickMathLib,createVaultParams.sqrtPriceMathLib,createVaultParams.liquidityMathLib,createVaultParams.safeCastLib,createVaultParams.liquidityAmountsLib,createVaultParams.fullMathLib,createVaultParams.rewardToLp0AddressPath,createVaultParams.rewardToLp0FeePath,createVaultParams.rewardToLp1AddressPath,createVaultParams.rewardToLp1FeePath ,createVaultParams.rewardtoNativeFeed,createVaultParams.assettoNativeFeed),
                                                        CommonAddresses(vaultAddress, router,NonfungiblePositionManager));
            vault.transferOwnership(msg.sender);
            vault.init(IStrategy(address(strategy)));
        }else if(_vaultType == VaultType.PRIVATE){
            RiveraAutoCompoundingVaultV2Private vault = new RiveraAutoCompoundingVaultV2Private(createVaultParams.asset,createVaultParams.tokenName, createVaultParams.tokenSymbol, createVaultParams.approvalDelay,createVaultParams.totalTvlCap);
            vaultAddress = address(vault);
            strategy=_createStrategy(CakePoolParams(createVaultParams.tickLower,createVaultParams.tickUpper,createVaultParams.stake,chef,reward,createVaultParams.tickMathLib,createVaultParams.sqrtPriceMathLib,createVaultParams.liquidityMathLib,createVaultParams.safeCastLib,createVaultParams.liquidityAmountsLib,createVaultParams.fullMathLib,createVaultParams.rewardToLp0AddressPath,createVaultParams.rewardToLp0FeePath,createVaultParams.rewardToLp1AddressPath,createVaultParams.rewardToLp1FeePath ,createVaultParams.rewardtoNativeFeed,createVaultParams.assettoNativeFeed),
                                                        CommonAddresses(vaultAddress, router,NonfungiblePositionManager));
            vault.transferOwnership(msg.sender);
            vault.init(IStrategy(address(strategy)));
        }else{
            RiveraAutoCompoundingVaultV2Whitelisted vault = new RiveraAutoCompoundingVaultV2Whitelisted(createVaultParams.asset,createVaultParams.tokenName, createVaultParams.tokenSymbol, createVaultParams.approvalDelay,createVaultParams.totalTvlCap);
            vaultAddress = address(vault);
            strategy=_createStrategy(CakePoolParams(createVaultParams.tickLower,createVaultParams.tickUpper,createVaultParams.stake,chef,reward,createVaultParams.tickMathLib,createVaultParams.sqrtPriceMathLib,createVaultParams.liquidityMathLib,createVaultParams.safeCastLib,createVaultParams.liquidityAmountsLib,createVaultParams.fullMathLib,createVaultParams.rewardToLp0AddressPath,createVaultParams.rewardToLp0FeePath,createVaultParams.rewardToLp1AddressPath,createVaultParams.rewardToLp1FeePath ,createVaultParams.rewardtoNativeFeed,createVaultParams.assettoNativeFeed),
                                                        CommonAddresses(vaultAddress, router,NonfungiblePositionManager));
            vault.transferOwnership(msg.sender);
            vault.init(IStrategy(address(strategy)));
        }

        allVaults.push(vaultAddress);
        emit VaultCreated(msg.sender, createVaultParams.stake,  vaultAddress);

    }

    function _createStrategy(CakePoolParams memory _cakePoolParams,CommonAddresses memory _commonaddresses) internal returns (CakeLpStakingV2  strategy){
        strategy = new CakeLpStakingV2(_cakePoolParams,_commonaddresses);
        strategy.transferOwnership(msg.sender);
        strategy.setManager(manager);
    }



    function listAllVaults() external view returns (address[] memory) {
        return allVaults;
    }

}
