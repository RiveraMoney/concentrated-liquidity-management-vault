pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";
 import "forge-std/Script.sol";
 import "forge-std/console2.sol";

contract LPPositionGetter is Script {

    address _owner = 0xd35A8C7CD5b47514e56c4Fa96aa79065410178a0;
    address _pool = 0x36696169C63e42cd08ce11f5deeBbCeBae652050;

    function getTokenIds(address lpTokenAddress, address owner) public view {
        IERC721Enumerable lpTokenContract = IERC721Enumerable(lpTokenAddress);
        uint256 balance = lpTokenContract.balanceOf(owner);

        for (uint256 i = 0; i < balance; i++) {
            console2.logUint(lpTokenContract.tokenOfOwnerByIndex(owner, i));
        }
    }

    function run() external view {
        console2.logString("sqrtPriceX96:");
        getTokenIds(_pool, _owner);
     }
}
