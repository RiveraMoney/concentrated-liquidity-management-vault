pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/libs/WhitelistFilter.sol";
import "@rivera/factories/staking/RiveraConcLpStakingStratFactory.sol";

contract HarvestMantle is Script {
    address[] _vaults = [0xbcA0d7dd435b52B5e69A265Ba54f2C2A5E9c6bB8];

    function run() public {
        uint256 ownerPrivateKey = 0xdff8d049b069f97d75a5021c3602165713192730bbca543e630d0b85385e49cb;

        vm.startBroadcast(ownerPrivateKey);
        for (uint256 i=0; i<_vaults.length; i++) {
            RiveraAutoCompoundingVaultV2Whitelisted vault = RiveraAutoCompoundingVaultV2Whitelisted(_vaults[i]);
            IStrategy strategy=vault.strategy();
            //harvest
            strategy.harvest();
            console.log("harvested");
            
        }
        vm.stopBroadcast();
    }

}
