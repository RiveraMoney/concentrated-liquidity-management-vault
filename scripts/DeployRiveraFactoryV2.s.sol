pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/PancakePublicVaultFactoryV2.sol";
import "@rivera/PancakeWhitelistedVaultFactoryV2.sol";
import "@rivera/PancakePrivateVaultFactoryV2.sol";
import "@rivera/PancakeStratFactoryV2.sol";

contract DeployRiveraFactoryV2 is Script {
  
    address _chef = 0x556B9306565093C855AEA9AE92A594704c2Cd59e;
    //common address
    address _router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    address _NonfungiblePositionManager =
        0x46A15B0b27311cedF172AB29E4f4766fbE7F4364;
    VaultType _vaultType;

    function setUp() public {
        _vaultType = VaultType.WHITELISTED;
    }

    function run() public {

        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 0);
        vm.startBroadcast(privateKey);

        PancakeStratFactoryV2 stratFactory = new PancakeStratFactoryV2();
        console.log("Strat Factory",address(stratFactory));
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
        console.log("Public Vault Factory",address(factory));
    }

     function _deployPrivateVaultFactory(PancakeStratFactoryV2 stratFactory) internal returns (address vaultAddress){
        
        PancakePrivateVaultFactoryV2 factory = new PancakePrivateVaultFactoryV2(
            _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Private Vault Factory",address(factory));
    }

    function _deployWhitelistedVaultFactory(PancakeStratFactoryV2 stratFactory) internal returns (address vaultAddress){
        
        PancakeWhitelistedVaultFactoryV2 factory = new PancakeWhitelistedVaultFactoryV2(
            _chef,
            _router,
            _NonfungiblePositionManager,
            address(stratFactory)
        );
        console.log("Whitelisted Factory",address(factory));
    }


}
