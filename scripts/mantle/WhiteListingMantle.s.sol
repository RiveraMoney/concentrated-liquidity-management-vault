pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/libs/WhitelistFilter.sol";
import "@rivera/factories/cake/PancakeStratFactoryV2.sol";

contract WhiteListingMantle is Script {
    address[] _vaults = [0xbcA0d7dd435b52B5e69A265Ba54f2C2A5E9c6bB8];
    address[] _users = [0x6946bE2c5Da1eFbCebebA864db3593460B96cdFf,0xB3a299Dd230Ec08266Cdb560Ca676293073366a6,0x59cA2ebfb74F6BC4BB2112984Fd047A2Ac0f787c,0x2F920Aa1C86BA564F1280EDFF40E6aC575225ceC,0xc60fE42A279A7F0A2D440BA1B3f3991088f01ce7,0x44B2d0642d222A06F14E319fbDbA518b296f10e5,0x61579fcF2306EA393C675dA8cf335dAa3773Fdc2,0x506119DD56D796eb75c9af855cD6355e3cE2E2E0];
    // address[] _users = [0x67D464D46b319055BE8Bc5070d2Cf446459367c4,0xcB1dF4B4cF12e39ff43201363896f457d0496550,0xA7376C779f30B0989C739ed79733Ad220C83b223,0x2cc32dEb1C534caeC4C9d2f54C330B57A3023Bcf,0x2fa6a4D2061AD9FED3E0a1A7046dcc9692dA6Da8];

    function run() public {
        uint256 ownerPrivateKey = 0xdff8d049b069f97d75a5021c3602165713192730bbca543e630d0b85385e49cb;

        vm.startBroadcast(ownerPrivateKey);
        for (uint256 i=0; i<_vaults.length; i++) {
            RiveraAutoCompoundingVaultV2Whitelisted vault = RiveraAutoCompoundingVaultV2Whitelisted(_vaults[i]);
            for(uint256 j=0; j<_users.length; j++){
                bool isWhitelisted = vault.whitelist(_users[j]);
                console.log("User", _users[j], "isWhitelisted", isWhitelisted);
                if(!isWhitelisted){
                    vault.newWhitelist(_users[j]);
                } else {
                    vault.removeWhitelist(_users[j]);
                }
            }
        }
        vm.stopBroadcast();
    }

}
