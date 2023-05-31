pragma solidity ^0.8.0;

import './interfaces/IRiveraAutoCompoundingVaultFactoryV2.sol';
import './strategies/cake/CakeLpStakingV2.sol';

contract PancakeStratFactoryV2 {

    function createStrat(CreateVaultParams memory createVaultParams, address vaultAddress, address user, address manager, address router, address NonfungiblePositionManager, address chef) external returns (address) {
        CakeLpStakingV2 strategy = new CakeLpStakingV2();
        strategy.init(CakePoolParams(createVaultParams.tickLower, createVaultParams.tickUpper, createVaultParams.stake, chef, createVaultParams.rewardToLp0AddressPath[0], createVaultParams.tickMathLib, 
        createVaultParams.sqrtPriceMathLib, createVaultParams.liquidityMathLib, createVaultParams.safeCastLib, createVaultParams.liquidityAmountsLib, createVaultParams.fullMathLib, 
        createVaultParams.rewardToLp0AddressPath, createVaultParams.rewardToLp0FeePath, createVaultParams.rewardToLp1AddressPath, createVaultParams.rewardToLp1FeePath, 
        createVaultParams.rewardtoNativeFeed, createVaultParams.assettoNativeFeed), CommonAddresses(vaultAddress, router, NonfungiblePositionManager));
        strategy.transferOwnership(user);
        strategy.setManager(manager);
        return address(strategy);
    }

}
