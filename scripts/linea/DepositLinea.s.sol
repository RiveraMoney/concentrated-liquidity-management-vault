pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";


contract DepositLinea is Script {
    address _vault = 0x2C043d7625Ff55b2DB2D8685F4E6506F02c6fAcC;
    address usdc=0xf56dc6695cF1f5c364eDEbC7Dc7077ac9B586068;
    uint256 depositAmount1=15e6;
    function run() public {
        uint256 ownerPrivateKey = 0x59183010a7734a1282ed073a330a1820c3237a362a64138c969bcb980bd7f638;//user1 main

        address user =vm.addr(ownerPrivateKey);
    
        console2.log("user",user);
        vm.startBroadcast(ownerPrivateKey);
        IERC20(usdc).approve(_vault, depositAmount1);

        RiveraAutoCompoundingVaultV2Public(_vault).deposit(depositAmount1,user);
        // RiveraAutoCompoundingVaultV2Public vault=RiveraAutoCompoundingVaultV2Public(_vault);
        // uint256 totalAssets=vault.totalAssets();
        // console.log("totalAssets",totalAssets);
        vm.stopBroadcast();
    }

}