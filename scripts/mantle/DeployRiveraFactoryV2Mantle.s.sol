pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/factories/cake/vault/PancakePublicVaultFactoryV2.sol";
import "@rivera/factories/cake/vault/PancakeWhitelistedVaultFactoryV2.sol";
import "@rivera/factories/cake/vault/PancakePrivateVaultFactoryV2.sol";
import "@rivera/factories/cake/PancakeStratFactoryV2.sol";

contract DeployRiveraFactoryV2Mantle is Script {
  
    address _chef = 0x200f1f16bcc98687cEEBfEF03b7722547963fedb;
    address _router = 0xE3a68317a2F1c41E5B2efBCe2951088efB0Cf524;
    address _NonfungiblePositionManager = 0x94705da51466F3Bb1E8c1591D71C09c9760f5F59;
    VaultType _vaultType = VaultType.WHITELISTED;

    function run() public {

        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 0);

        vm.startBroadcast(privateKey);
        PancakeStratFactoryV2 stratFactory = new PancakeStratFactoryV2();
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


    function _deployPublicVaultFactory(PancakeStratFactoryV2 stratFactory) internal returns (address vaultAddress){
        
        PancakePublicVaultFactoryV2 factory = new PancakePublicVaultFactoryV2(
            _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Public Vault Factory", address(factory));
    }

     function _deployPrivateVaultFactory(PancakeStratFactoryV2 stratFactory) internal returns (address vaultAddress){
        
        PancakePrivateVaultFactoryV2 factory = new PancakePrivateVaultFactoryV2(
            _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Private Vault Factory", address(factory));
    }

    function _deployWhitelistedVaultFactory(PancakeStratFactoryV2 stratFactory) internal returns (address vaultAddress){
        
        PancakeWhitelistedVaultFactoryV2 factory = new PancakeWhitelistedVaultFactoryV2(
            _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Whitelisted Factory", address(factory));
    }


}
