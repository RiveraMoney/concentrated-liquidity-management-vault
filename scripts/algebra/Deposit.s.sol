pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";


contract Deposit is Script {
    address _vault = 0x10DAF097374e6C4F6f2fcBD2586519E9cBb803D3;
    address depositToken=0xD102cE6A4dB07D247fcc28F366A623Df0938CA9E;
    function run() public {
        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKeyUser = vm.deriveKey(seedPhrase, 2);
        address user =vm.addr(privateKeyUser);
        console2.log("user",user);
        vm.startBroadcast(privateKeyUser);
        uint256 depositAmount1=IERC20(depositToken).balanceOf(user)/10;
        IERC20(depositToken).approve(_vault, depositAmount1);
        RiveraAutoCompoundingVaultV2Public(_vault).deposit(depositAmount1,user);
        vm.stopBroadcast();
    }

}