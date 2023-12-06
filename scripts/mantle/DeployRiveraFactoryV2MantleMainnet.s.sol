pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/factories/staking/vault/RiveraALMVaultFactoryPublic.sol";
import "@rivera/factories/staking/vault/RiveraALMVaultFactoryWhitelisted.sol";
import "@rivera/factories/staking/vault/RiveraALMVaultFactoryPrivate.sol";
import "@rivera/factories/staking/RiveraALMStrategyFactory.sol";

contract DeployRiveraFactoryV2MantleMainnet is Script {
  
    // address _chef = 0x9316938Eaa09E71CBB1Bf713212A42beCBa2998F;//testnet till we get mainnet address
    address _router = 0x319B69888b0d11cEC22caA5034e25FfFBDc88421;//maninnet agni
    address _NonfungiblePositionManager =0x218bf598D1453383e2F4AA7b14fFB9BfB102D637;//maninnet agni
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
            // _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Public Vault Factory", address(factory));
    }

     function _deployPrivateVaultFactory(RiveraALMStrategyFactory stratFactory) internal returns (address vaultAddress){
        
        RiveraALMVaultFactoryPrivate factory = new RiveraALMVaultFactoryPrivate(
            // _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Private Vault Factory", address(factory));
    }

    function _deployWhitelistedVaultFactory(RiveraALMStrategyFactory stratFactory) internal returns (address vaultAddress){
        
        RiveraALMVaultFactoryWhitelisted factory = new RiveraALMVaultFactoryWhitelisted(
            // _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Whitelisted Factory", address(factory));
    }


}
