pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";

contract ChangeTvl is Script {
    address _vault=0x10DAF097374e6C4F6f2fcBD2586519E9cBb803D3;
    uint256 newTvlCap=100000e18;
    function run() public {
        string memory seedPhrase = vm.readFile(".secret");

        uint256 _ownerPrivateKey = vm.deriveKey(seedPhrase, 1);
        address owner = vm.addr(_ownerPrivateKey);

        uint256 _managerPrivateKey = vm.deriveKey(seedPhrase, 0);
        address manager = vm.addr(_managerPrivateKey);

        vm.startBroadcast(_ownerPrivateKey);

        RiveraAutoCompoundingVaultV2Whitelisted vault=RiveraAutoCompoundingVaultV2Whitelisted(_vault);
        //old tvl cap
        console2.logUint(vault.totalTvlCap());
        vault.setTotalTvlCap(newTvlCap);
        //new tvl cap
        console2.logUint(vault.totalTvlCap());


        vm.stopBroadcast();

    }

}
