pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/libs/WhitelistFilter.sol";
import "@rivera/factories/cake/PancakeStratFactoryV2.sol";

contract DepositMantle is Script {
    address _vault =0x9dc06e7729FD4f8dcf33b3b75f64CDeDeBdc4759;
    address asset=0xB38E748dbCe79849b8298A1D206C8374EFc16DA7;
    uint256 depositAmount1=1482608838390234;
    address user;

    function run() public {
        // uint256 userPrivateKey = 0958cf899a1c6402a85cc28c88640af985b15a7fa90a8a09a37f03ec4f5a1a89;
        string memory seedPhrase = vm.readFile(".secret");
        uint256 userPrivateKey = vm.deriveKey(seedPhrase, 2);
        user=vm.addr(userPrivateKey);
        vm.startBroadcast(userPrivateKey);
            RiveraAutoCompoundingVaultV2Whitelisted vault = RiveraAutoCompoundingVaultV2Whitelisted(_vault);
            // IStrategy strategy=vault.strategy();
            //deposit
            IERC20(asset).approve(_vault, depositAmount1);
            vault.deposit(depositAmount1,user);
            console.log("deposited");
            
        vm.stopBroadcast();
    }

}
