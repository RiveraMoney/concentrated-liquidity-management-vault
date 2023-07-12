pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/factories/staking/vault/RiveraConcLiqStakingPubVaultFactory.sol";
import "@rivera/factories/staking/vault/RiveraConcLiqStakingWhiLisVaultFactory.sol";
import "@rivera/factories/staking/vault/RiveraConcLiqStakingPrivVaultFactory.sol";
import "@rivera/factories/staking/RiveraConcLpStakingStratFactory.sol";

contract DeployRiveraFactoryV2Mantle is Script {
  
    address _chef = 0x9316938Eaa09E71CBB1Bf713212A42beCBa2998F;
    address _router = 0xE3a68317a2F1c41E5B2efBCe2951088efB0Cf524;
    address _NonfungiblePositionManager = 0x94705da51466F3Bb1E8c1591D71C09c9760f5F59;
    VaultType _vaultType = VaultType.WHITELISTED;

    function run() public {

        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 0);

        vm.startBroadcast(privateKey);
        RiveraConcLpStakingStratFactory stratFactory = new RiveraConcLpStakingStratFactory();
        console.log("Strat Factory", address(stratFactory));
        if(_vaultType == VaultType.PUBLIC){
            _deployPublicVaultFactory(stratFactory);
        }else if(_vaultType == VaultType.PRIVATE){
            _deployPrivateVaultFactory(stratFactory);
        }else if(_vaultType == VaultType.WHITELISTED){
            _deployWhitelistedVaultFactory(stratFactory);
        }
        vm.stopBroadcast();

    }


    function _deployPublicVaultFactory(RiveraConcLpStakingStratFactory stratFactory) internal returns (address vaultAddress){
        
        RiveraConcLiqStakingPubVaultFactory factory = new RiveraConcLiqStakingPubVaultFactory(
            _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Public Vault Factory", address(factory));
    }

     function _deployPrivateVaultFactory(RiveraConcLpStakingStratFactory stratFactory) internal returns (address vaultAddress){
        
        RiveraConcLiqStakingPrivVaultFactory factory = new RiveraConcLiqStakingPrivVaultFactory(
            _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Private Vault Factory", address(factory));
    }

    function _deployWhitelistedVaultFactory(RiveraConcLpStakingStratFactory stratFactory) internal returns (address vaultAddress){
        
        RiveraConcLiqStakingWhiLisVaultFactory factory = new RiveraConcLiqStakingWhiLisVaultFactory(
            _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Whitelisted Factory", address(factory));
    }


}
