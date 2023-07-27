pragma solidity ^0.8.0;

import './RiveraLpStakingVaultCreationStruct.sol';
import '@rivera/strategies/staking/RiveraConcLpStakingGen.sol';

contract RiveraALMStrategyFactory {

    function createStrat(RiveraVaultParams memory createVaultParams, address vaultAddress, address user, address manager, address router, address nonfungiblePositionManager, address chef, 
    FeeParams memory feeParams) external returns (address) {
        RiveraConcLpStakingGen strategy = new RiveraConcLpStakingGen();
        strategy.init(RiveraLpStakingParams(createVaultParams.tickLower, createVaultParams.tickUpper, createVaultParams.stake, chef, createVaultParams.rewardToLp0AddressPath[0], createVaultParams.tickMathLib, 
        createVaultParams.sqrtPriceMathLib, createVaultParams.liquidityMathLib, createVaultParams.safeCastLib, createVaultParams.liquidityAmountsLib, createVaultParams.fullMathLib, 
        createVaultParams.rewardToLp0AddressPath, createVaultParams.rewardToLp0FeePath, createVaultParams.rewardToLp1AddressPath, createVaultParams.rewardToLp1FeePath, 
        createVaultParams.rewardtoNativeFeed, createVaultParams.assettoNativeFeed,createVaultParams.pendingReward), CommonAddresses(vaultAddress, router, nonfungiblePositionManager, feeParams.withdrawFeeDecimals, 
        feeParams.withdrawFee, feeParams.feeDecimals, feeParams.protocolFee, feeParams.fundManagerFee, feeParams.partnerFee, feeParams.partner));
        strategy.transferOwnership(user);
        strategy.setManager(manager);
        return address(strategy);
    }

}
