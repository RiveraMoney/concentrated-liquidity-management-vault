pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/libs/WhitelistFilter.sol";
import "@rivera/factories/cake/PancakeStratFactoryV2.sol";

contract WhiteListing is Script {
    address _vaultBnb=0x10DAF097374e6C4F6f2fcBD2586519E9cBb803D3;
    address _vaultEth=0x8Ff3b85b341fAd37417f77567624b08B5142fD5c;
    address [] users=[0xcf288Dc70983D17C83EA1b80579b211c51043801,0xe620Ddc3b46FC30D7Ba98C6B315aA17f69302B0c,0xE1427B8A742f489c866C42874F83aFc0c5D003e8];

    function run() public {

        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 1);

        vm.startBroadcast(privateKey);
        RiveraAutoCompoundingVaultV2Whitelisted vaultBnb = RiveraAutoCompoundingVaultV2Whitelisted(_vaultBnb);
        RiveraAutoCompoundingVaultV2Whitelisted vaultEth = RiveraAutoCompoundingVaultV2Whitelisted(_vaultEth);
        for(uint i=0;i<users.length;i++){
            bool isWhitelisted = vaultBnb.whitelist(users[i]);
            console.log("User",users[i],"isWhitelisted",isWhitelisted);
            if(!isWhitelisted){
                vaultBnb.newWhitelist(users[i]);
                vaultEth.newWhitelist(users[i]);
            }else
            {
                vaultBnb.removeWhitelist(users[i]);
                vaultEth.removeWhitelist(users[i]);
            }
        }

        vm.stopBroadcast();
    }

}
