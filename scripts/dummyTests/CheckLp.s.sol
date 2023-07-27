pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
// import "@rivera/factories/cake/PancakeStratFactoryV2.sol";


//interface of panckahe swap lp pool contract
interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}
contract CheckLp is Script {
    address _stake=0x8Cbe9ae3ac41C057A557B94FCF682F19d7BBc92C;

    function run() public {

        //get token0 and token1 of lp pool
        IPancakePair lp = IPancakePair(_stake);
        address token0 = lp.token0();
        address token1 = lp.token1();
        console.log("token0: %s", token0);
        console.log("token1: %s", token1);

    }

}
