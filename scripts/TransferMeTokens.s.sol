// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "forge-std/Script.sol";
// import "forge-std/console2.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract MyScript is Script {

//     address _token = 0x804678fa97d91B974ec2af3c843270886528a9E6;     //The token of which you want some
//     address _whale = 0x1cbD4cAb7006EAE6c7e3C65eDcFA9411dC3c8c30;     //The person who has a lot of ths token to take from
//     address _myUserAccount = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;     //Your browser metamask account. The account to which you want to transfer the token
//     uint256 _amount = 1000e18;       //Amount of tokens you want to transfer to yourself from the whale. This should be less than the whale's balance

//     function run() external {
//         console2.logString("Balance of user account before:");
//         console2.logUint(IERC20(_token).balanceOf(_myUserAccount));
//         vm.startPrank(_whale);
//         IERC20(_token).transfer(_myUserAccount, _amount);
//         vm.stopPrank();
//         console2.logString("Balance of user account after:");
//         console2.logUint(IERC20(_token).balanceOf(_myUserAccount));
//     }
// }