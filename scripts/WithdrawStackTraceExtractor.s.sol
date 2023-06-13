pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";


contract WithdrawStackTraceExtractor is Script {

    uint256 _privateKey3;
    address _user3;
    address vault = 0x4C4A11B5FbAe47a6303F9aC8585584a40ba476c4;
    uint256 depositAmount = 1e15;

    function setUp() public {
        string memory seedPhrase = vm.readFile(".secret");

        uint256 privateKey3 = vm.deriveKey(seedPhrase, 2);
        _privateKey3=privateKey3;
        ///user3 will be
        _user3 = vm.addr(privateKey3);
    }

    function run() public {
        console.log("======================Deposit in Vaults====================");
        vm.startBroadcast(_privateKey3);
        //deposit in vault
        // console2.log("wbnb balance");
        // console2.log(IERC20(_wbnb).balanceOf(_user3));
        RiveraAutoCompoundingVaultV2Whitelisted(vault).withdraw(depositAmount, _user3, _user3);

        vm.stopBroadcast();
    }
}