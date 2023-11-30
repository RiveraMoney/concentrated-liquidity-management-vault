pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "@rivera/libs/WhitelistFilter.sol";
// import "@rivera/factories/staking/RiveraConcLpStakingStratFactory.sol";

contract TestVault is Script {
    address vault = 0x10DAF097374e6C4F6f2fcBD2586519E9cBb803D3;
    uint256 ownerPrivateKey;
    address owner;
    uint256 managerPrivateKey;
    address manager;
    uint256 userPrivateKey;
    address user;
    int24 newTickLower=-97000; 
    int24 newTickUpper=-51000; 



    function setUp() public {
        string memory seedPhrase = vm.readFile(".secret");
        uint256 _ownerPrivateKey = vm.deriveKey(seedPhrase, 1);
        ownerPrivateKey=_ownerPrivateKey;
        owner = vm.addr(ownerPrivateKey);

        uint256 _managerPrivateKey = vm.deriveKey(seedPhrase, 0);
        managerPrivateKey=_managerPrivateKey;
        manager = vm.addr(managerPrivateKey);

        uint256 _userPrivateKey = vm.deriveKey(seedPhrase, 2);
        userPrivateKey=_userPrivateKey;
        user = vm.addr(userPrivateKey);
    }

    function run() public {
        RiveraAutoCompoundingVaultV2Public vault = RiveraAutoCompoundingVaultV2Public(vault);
        IStrategy strategy=vault.strategy();
        address depositToken=vault.asset();
        console.log("depositToken",depositToken);

        uint256 maxwi=vault.maxWithdraw(user);


        console.log("===================================");
        console.log("check withdraw and then deposit");
        console.log("max withdraw",maxwi);

        vm.startBroadcast(userPrivateKey);
        vault.withdraw(maxwi, user, user);
        console.log("Withdraw done");
        uint256 depositAmount1=IERC20(depositToken).balanceOf(user)/2;
        IERC20(depositToken).approve(address(vault), depositAmount1);
        vault.deposit(depositAmount1,user);
        console.log("Deposit done");
        vm.stopBroadcast();



        // console.log("===================================");
        // console.log("check changeRange");
        // vm.startBroadcast(ownerPrivateKey);
        // int24 tickLowerBnb=strategy.tickLower();
        // int24 tickUpperBnb=strategy.tickUpper();
        // console2.logInt(tickLowerBnb);
        // console2.logInt(tickUpperBnb);

        // strategy.changeRange(newTickLower,newTickUpper);

        // tickLowerBnb=strategy.tickLower();
        // tickUpperBnb=strategy.tickUpper();
        // console2.logInt(tickLowerBnb);
        // console2.logInt(tickUpperBnb);
        // vm.stopBroadcast();

        // console.log("check changing total tvl cap");
        vm.startBroadcast(ownerPrivateKey);
        uint256 totalTvlCapBefore=vault.totalTvlCap();
        console.log("totalTvlCapBefore",totalTvlCapBefore);
        vault.setTotalTvlCap(100000000e18);
        uint256 totalTvlCapAfter=vault.totalTvlCap();
        console.log("totalTvlCapAfter",totalTvlCapAfter);
        vm.stopBroadcast();
        console.log("===================================");
        console.log("check panic");
        vm.startBroadcast(managerPrivateKey);
        uint256 balanceOfStratBefore=strategy.balanceOf();
        console.log("balanceOfStratBefore",balanceOfStratBefore);
        strategy.panic();
        uint256 balanceOfStratAfter=strategy.balanceOf();
        console.log("balanceOfStratAfter",balanceOfStratAfter);
        vm.stopBroadcast();
        vm.startBroadcast(userPrivateKey);
        uint256 balanceOfStratBeforeWithdraw=strategy.balanceOf();
        console.log("balanceOfStratBeforeWithdraw",balanceOfStratBeforeWithdraw);
        uint256 maxWithdraw=vault.maxWithdraw(user);
        vault.withdraw(maxWithdraw, user, user);
        uint256 balanceOfStratAfterWithdraw=strategy.balanceOf();
        console.log("balanceOfStratAfterWithdraw",balanceOfStratAfterWithdraw);
        vm.stopBroadcast();
        vm.startBroadcast(managerPrivateKey);

        uint256  tokenId=strategy.tokenID();
        console.log("tokenId after panic",tokenId);
        console.log("===================================");
        console.log("check unpause");
        strategy.unpause();
        tokenId=strategy.tokenID();
        console.log("tokenId after unpause",tokenId);
        vm.stopBroadcast();
        vm.startBroadcast(userPrivateKey);

        depositAmount1=IERC20(depositToken).balanceOf(user)/2;
        console.log("depositAmount1",depositAmount1);
        IERC20(depositToken).approve(address(vault), depositAmount1);
        vault.deposit(depositAmount1,user);
        console.log("Deposit done");
        tokenId=strategy.tokenID();
        console.log("tokenId after deposit",tokenId);

        //lp0 token balances
        // IERC20 _lp0Token=strategy.lpToken0();
        // IERC20 _lp1Token=strategy.lpToken1();

        // uint256 lp0Balance =_lp0Token.balanceOf(address(strategy));
        // console.log("lp0Balance strat", lp0Balance);
        // lp0Balance =_lp0Token.balanceOf(address(strategy));
        // console.log("lp0Balance vault", lp0Balance);
        
        // uint256 lp1Balance =_lp1Token.balanceOf(address(strategy));
        // console.log("lp1Balance strat", lp1Balance);
        // lp1Balance =_lp1Token.balanceOf(address(strategy));
        // console.log("lp1Balance vault", lp1Balance);




    }

}