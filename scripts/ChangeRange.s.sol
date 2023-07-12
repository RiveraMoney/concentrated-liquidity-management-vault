pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/factories/staking/RiveraConcLpStakingStratFactory.sol";

contract ChangeRange is Script {
    address _vaultBnb=0x10DAF097374e6C4F6f2fcBD2586519E9cBb803D3;
    address _vaultEth=0x8Ff3b85b341fAd37417f77567624b08B5142fD5c;
    int24 newTickLowerBnb=610;
    int24 newTickUpperBnb=630;
    int24 newTickLowerEth=-1100;
    int24 newTickUpperEth=-1090;

    function run() public {

        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 1);

        vm.startBroadcast(privateKey);
        IStrategy strategyBnb=RiveraAutoCompoundingVaultV2Whitelisted(_vaultBnb).strategy();
        IStrategy strategyEth=RiveraAutoCompoundingVaultV2Whitelisted(_vaultEth).strategy();

        strategyBnb.changeRange(newTickLowerBnb,newTickUpperBnb);
        strategyEth.changeRange(newTickLowerEth,newTickUpperEth);

        int24 tickLowerBnb=strategyBnb.tickLower();
        int24 tickUpperBnb=strategyBnb.tickUpper();
        int24 tickLowerEth=strategyEth.tickLower();
        int24 tickUpperEth=strategyEth.tickUpper();
        //print tick range
        console2.logInt(tickLowerBnb);
        console2.logInt(tickUpperBnb);
        console2.logInt(tickLowerEth);
        console2.logInt(tickUpperEth);  

        vm.stopBroadcast();

    }

}
