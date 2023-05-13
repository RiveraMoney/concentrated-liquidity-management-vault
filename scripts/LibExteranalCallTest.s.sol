//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/cake/interfaces/ITickMathLib.sol";

 contract LibExternalCallTest is Script {

     address _tickMath = 0xbA839d70B635A27bB0481731C05c24aDa7Fc9Db9;

     function run() external view {
        console2.logString("sqrtRatioAtTick:");
        uint160 result = ITickMathLib(_tickMath).getSqrtRatioAtTick(10);
         console2.logUint(result);
     }
 }