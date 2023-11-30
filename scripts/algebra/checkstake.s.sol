pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/strategies/staking/interfaces/IAlgebraPoolStake.sol";
import "@pancakeswap-v3-core/interfaces/IPancakeV3Pool.sol";


interface Wdep {
    function deposit() external payable;
}

contract checkstake is Script {
    address stake=0xF9a8400FA03316aF5f49654D43676f8A29B164DC;

    function run() public {

        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKeyUser = vm.deriveKey(seedPhrase, 2);
        address _user3 = vm.addr(privateKeyUser);

        address lpToken0 = IAlgebraPoolStake(stake).token0();
        address lpToken1 = IAlgebraPoolStake(stake).token1();

        (uint160 sqrtPriceX96, int24 tick, , , ,  ) = IAlgebraPoolStake(stake).globalState();
        address factory = IAlgebraPoolStake(stake).factory();
        int24 tickSpacing = IAlgebraPoolStake(stake).tickSpacing();
        // console2   .
        console.log("sqrtPriceX96",sqrtPriceX96);
        console2.logInt(tick);
        console2.logInt(tickSpacing);

        console.log("stake",stake);
        console.log("factory",factory);
        console.log("lpToken0",lpToken0);
        console.log("lpToken1",lpToken1);

        // console.log("lp0Balance",IERC20(lpToken0).balanceOf(0xf257E2a26A96cdC1D28e5b7a626f624fF8692dD6));
        // console.log("lp1Balance",IERC20(lpToken1).balanceOf(0xf257E2a26A96cdC1D28e5b7a626f624fF8692dD6));
        vm.startBroadcast(privateKeyUser);
        Wdep(lpToken1).deposit{ value: 10000000000000000000 }();
        console.log("lp1Balance",IERC20(lpToken1).balanceOf(_user3));

        }
    }

