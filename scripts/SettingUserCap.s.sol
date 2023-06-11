pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/factories/cake/PancakeStratFactoryV2.sol";

contract SettingUserCap is Script {
    address _vaultBnb=0x10DAF097374e6C4F6f2fcBD2586519E9cBb803D3;
    address _vaultEth=0x8Ff3b85b341fAd37417f77567624b08B5142fD5c;
    address _user=0xcf288Dc70983D17C83EA1b80579b211c51043801;
    uint256 _userCapBnb=100000000000000000000;
    uint256 _userCapEth=100000000000000000000;

    function run() public {

        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 1);

        vm.startBroadcast(privateKey);
        RiveraAutoCompoundingVaultV2Whitelisted(_vaultBnb).setUserTvlCap(_user, _userCapBnb);
        RiveraAutoCompoundingVaultV2Whitelisted(_vaultEth).setUserTvlCap(_user, _userCapEth);
        uint256 userCapBnb= RiveraAutoCompoundingVaultV2Whitelisted(_vaultBnb).userTvlCap(_user);
        uint256 userCapEth= RiveraAutoCompoundingVaultV2Whitelisted(_vaultEth).userTvlCap(_user);
        console.log("userCapBnb",userCapBnb);
        console.log("userCapEth",userCapEth);

        vm.stopBroadcast();

    }

}
