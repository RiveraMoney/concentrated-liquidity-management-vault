pragma solidity ^0.8.0;

import '@rivera/strategies/cake/VenusMarketNeutralCakeLpStakingV1.sol';
import '../cake/PancakeVaultCreationStruct.sol';

contract PancakeVenusMarketNeutralCakeLpStakingFactory {

    function createStrat(PancakeVaultParams memory createVaultParams, address vaultAddress, address user, address manager, address router, 
    address NonfungiblePositionManager, address chef, VenusMarketNeutralParams calldata venusMarketNeutralParams) external returns (address) {
        VenusMarketNeutralCakeLpStakingV1 strategy = new VenusMarketNeutralCakeLpStakingV1();
        strategy.init(CakePoolParams(createVaultParams.tickLower, createVaultParams.tickUpper, createVaultParams.stake, chef, createVaultParams.rewardToLp0AddressPath[0], createVaultParams.tickMathLib, 
        createVaultParams.sqrtPriceMathLib, createVaultParams.liquidityMathLib, createVaultParams.safeCastLib, createVaultParams.liquidityAmountsLib, createVaultParams.fullMathLib, 
        createVaultParams.rewardToLp0AddressPath, createVaultParams.rewardToLp0FeePath, createVaultParams.rewardToLp1AddressPath, createVaultParams.rewardToLp1FeePath, 
        createVaultParams.rewardtoNativeFeed, createVaultParams.assettoNativeFeed), CommonAddresses(vaultAddress, router, NonfungiblePositionManager), 
        venusMarketNeutralParams.safetyFactor_, venusMarketNeutralParams.vToken0_, venusMarketNeutralParams.vToken1_, venusMarketNeutralParams.distribution_);
        strategy.transferOwnership(user);
        strategy.setManager(manager);
        return address(strategy);
    }

}
