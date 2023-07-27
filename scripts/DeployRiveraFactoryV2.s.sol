pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/factories/staking/vault/RiveraALMVaultFactoryPublic.sol";
import "@rivera/factories/staking/vault/RiveraALMVaultFactoryWhitelisted.sol";
import "@rivera/factories/staking/vault/RiveraALMVaultFactoryPrivate.sol";
import "@rivera/factories/staking/RiveraALMStrategyFactory.sol";

contract DeployRiveraFactoryV2 is Script {
  
    address _chef = 0x556B9306565093C855AEA9AE92A594704c2Cd59e;
    address _router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    address _NonfungiblePositionManager = 0x46A15B0b27311cedF172AB29E4f4766fbE7F4364;
    VaultType _vaultType = VaultType.WHITELISTED;

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
