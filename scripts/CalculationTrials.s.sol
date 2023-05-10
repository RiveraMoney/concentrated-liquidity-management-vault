//  SPDX-License-Identifier: UNLICENSED
 pragma solidity ^0.8.13;

 import "forge-std/Script.sol";
 import "forge-std/console2.sol";
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@rivera/interfaces/IPancakeV3PoolState.sol";

 contract CalculationScript is Script {

     address _pool = 0x7f51c8AaA6B0599aBd16674e2b17FEc7a9f674A1;

     function run() external view {
        console2.logString("sqrtPriceX96:");
        (uint160 sqrtPriceX96, , , , , , ) = IPancakeV3PoolState(_pool).slot0();
         console2.logUint(sqrtPriceX96);
     }
 }