pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/libs/WhitelistFilter.sol";
import "@rivera/factories/cake/PancakeStratFactoryV2.sol";

contract WhiteListing is Script {
    address[] _vaults = [0x4C4A11B5FbAe47a6303F9aC8585584a40ba476c4, 0x1b88557d928f27ea912DA095D5991A253293b1a7];
    address[] _users = [0xA7376C779f30B0989C739ed79733Ad220C83b223];

    function run() public {
        uint256 ownerPrivateKey = 0x216653d326fc394b6c8c608750f4379a84eb7f9d97c0e6cd0f7e7c0c2c6a7f5e;

        vm.startBroadcast(ownerPrivateKey);
        for (uint256 i=0; i<_vaults.length; i++) {
            RiveraAutoCompoundingVaultV2Whitelisted vault = RiveraAutoCompoundingVaultV2Whitelisted(_vaults[i]);
            for(uint256 j=0; j<_users.length; j++){
                bool isWhitelisted = vault.whitelist(_users[j]);
                console.log("User", _users[j], "isWhitelisted", isWhitelisted);
                if(!isWhitelisted){
                    vault.newWhitelist(_users[j]);
                } else {
                    vault.removeWhitelist(_users[j]);
                }
            }
        }
        vm.stopBroadcast();
    }

}
