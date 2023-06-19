pragma solidity ^0.8.0;

import './PancakeVaultCreationStruct.sol';
import '@rivera/strategies/cake/CakeLpStakingV2.sol';

contract PancakeStratFactoryV2 {

    function createStrat(PancakeVaultParams memory createVaultParams, address vaultAddress, address user, address manager, address router, address nonfungiblePositionManager, address chef) external returns (address) {
        CakeLpStakingV2 strategy = new CakeLpStakingV2();
        strategy.init(CakePoolParams(createVaultParams.tickLower, createVaultParams.tickUpper, createVaultParams.stake, chef, createVaultParams.rewardToLp0AddressPath[0], createVaultParams.tickMathLib, 
        createVaultParams.sqrtPriceMathLib, createVaultParams.liquidityMathLib, createVaultParams.safeCastLib, createVaultParams.liquidityAmountsLib, createVaultParams.fullMathLib, 
        createVaultParams.rewardToLp0AddressPath, createVaultParams.rewardToLp0FeePath, createVaultParams.rewardToLp1AddressPath, createVaultParams.rewardToLp1FeePath, 
        createVaultParams.rewardtoNativeFeed, createVaultParams.assettoNativeFeed,createVaultParams.pendingReward), CommonAddresses(vaultAddress, router, nonfungiblePositionManager));
        strategy.transferOwnership(user);
        strategy.setManager(manager);
        return address(strategy);
    }

}
