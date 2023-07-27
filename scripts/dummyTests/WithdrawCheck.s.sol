pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/factories/cake/PancakeStratFactoryV2.sol";

contract WithdrawCheck is Script {
    address _vaultBnb=0x10DAF097374e6C4F6f2fcBD2586519E9cBb803D3;
    address _vaultEth=0x8Ff3b85b341fAd37417f77567624b08B5142fD5c;


    address _cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //Adress of the CAKE ERC20 token on mainnet
    address _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //Address of wrapped version of BNB which is the native token of BSC
    address _usdt = 0x55d398326f99059fF775485246999027B3197955;
    address _bnbx=0x1bdd3Cf7F79cfB8EdbB955f20ad99211551BA275;
    address _ankrEth=0xe05A08226c49b636ACf99c40Da8DC6aF83CE5bB3;
    address _eth=0x2170Ed0880ac9A755fd29B2688956BD959F933F8;

    function run() public {

        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 3);
        address user=vm.addr(privateKey);

        vm.startBroadcast(privateKey);
        RiveraAutoCompoundingVaultV2Whitelisted vaultBnb=RiveraAutoCompoundingVaultV2Whitelisted(_vaultBnb);
        IStrategy strategyBnb=vaultBnb.strategy();


        uint256 rewardsAvailable=strategyBnb.rewardsAvailable();
        console.log("rewardsAvailable",rewardsAvailable);

        // //bnb balance of user before
        // uint256 bnbBalanceBefore=IERC20(_wbnb).balanceOf(user);
        // console.log("bnbBalanceBefore",bnbBalanceBefore);

        // //max withdrawable amount
        // uint256 maxWithdrawableAmount=vaultBnb.maxWithdraw(user);
        // //withdraw from vault bnb
        // uint256 amountBnb=vaultBnb.totalAssets();
        // console.log("amountBnb",amountBnb);
        // vaultBnb.withdraw(maxWithdrawableAmount,user,user);

        // //bnb balance of user after
        // uint256 bnbBalanceAfter=IERC20(_wbnb).balanceOf(user);
        // console.log("bnbBalanceAfter",bnbBalanceAfter);
        vm.stopBroadcast();

    }

}
