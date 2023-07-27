pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/factories/staking/vault/RiveraALMVaultFactoryPublic.sol";
import "@rivera/factories/staking/vault/RiveraALMVaultFactoryWhitelisted.sol";
import "@rivera/factories/staking/vault/RiveraALMVaultFactoryPrivate.sol";
import "@rivera/factories/staking/RiveraALMStrategyFactory.sol";

contract DeployRiveraFactoryLineaTestnet is Script {
  
    address _chef = address(0);
    address _router = 0x6aa397CAB00a2A40025Dbf839a83f16D5EC7c1eB;
    address _NonfungiblePositionManager = 0xBa2e5317CC21CF591d3908F703a855547cDc849f;
    VaultType _vaultType = VaultType.PUBLIC;

    function run() public {

        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 0);

        vm.startBroadcast(privateKey);
        RiveraALMStrategyFactory stratFactory = new RiveraALMStrategyFactory();
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


    function _deployPublicVaultFactory(RiveraALMStrategyFactory stratFactory) internal returns (address vaultAddress){
        
        RiveraALMVaultFactoryPublic factory = new RiveraALMVaultFactoryPublic(
            _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Public Vault Factory", address(factory));
    }

     function _deployPrivateVaultFactory(RiveraALMStrategyFactory stratFactory) internal returns (address vaultAddress){
        
        RiveraALMVaultFactoryPrivate factory = new RiveraALMVaultFactoryPrivate(
            _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Private Vault Factory", address(factory));
    }

    function _deployWhitelistedVaultFactory(RiveraALMStrategyFactory stratFactory) internal returns (address vaultAddress){
        
        RiveraALMVaultFactoryWhitelisted factory = new RiveraALMVaultFactoryWhitelisted(
            _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Whitelisted Factory", address(factory));
    }


}
