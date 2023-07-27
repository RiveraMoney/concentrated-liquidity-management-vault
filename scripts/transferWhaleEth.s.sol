pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "forge-std/StdUtils.sol";


contract transferWhaleEth is Script {
    address _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //Address of wrapped version of BNB which is the native token of BSC

    address _whaleBnb=	0x8FA59693458289914dB0097F5F366d771B7a7C3F;



    function setUp() public {

    }

    function run() public {

        vm.deal(address(_whaleBnb),1e18);

    }

}

