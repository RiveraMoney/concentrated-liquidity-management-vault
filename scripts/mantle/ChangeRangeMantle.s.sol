

pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/factories/cake/PancakeStratFactoryV2.sol";

contract ChangeRangeMantle is Script {
    address _vault=0x4Eb4378F1fFe76e2F91074FA36cEF04261BB50F5;
    int24 newTickLower=65800;
    int24 newTickUpper=67900;

    function run() public {

        uint256 ownerPrivateKey = 0xdff8d049b069f97d75a5021c3602165713192730bbca543e630d0b85385e49cb;

        vm.startBroadcast(ownerPrivateKey);
        IStrategy strategy=RiveraAutoCompoundingVaultV2Whitelisted(_vault).strategy();

        strategy.changeRange(newTickLower,newTickUpper);

        int24 tickLowerBnb=strategy.tickLower();
        int24 tickUpperBnb=strategy.tickUpper();
        //print tick range
        console2.logInt(tickLowerBnb);
        console2.logInt(tickUpperBnb);

        vm.stopBroadcast();

    }

}
