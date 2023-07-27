pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";

enum VaultType {
        PRIVATE ,
        PUBLIC,
        WHITELISTED
    }

interface IRiveraVaultFactoryV2
 {
    event VaultCreated(address indexed user, address indexed stake, address vault);

    function allVaults(uint) external view returns (address vault);
    function listAllVaults() external view returns (address[] memory);
    function vaultType() external view returns (VaultType);

}


contract CheckLinea is Script {
  
    address vaultFactory=0x6F1138F2c619C54F87A4Cb95E42d3B275e155650 ;

    function run() public {

        address [] memory allVaults=IRiveraVaultFactoryV2(vaultFactory).listAllVaults();

        VaultType vaultType=IRiveraVaultFactoryV2(vaultFactory).vaultType();
        if(vaultType==VaultType.PRIVATE){
            console.log("VaultType","PRIVATE");
        }else if(vaultType==VaultType.PUBLIC){
            console.log("VaultType","PUBLIC");
        }else if(vaultType==VaultType.WHITELISTED){
            console.log("VaultType","WHITELISTED");
        }

        for(uint i=0;i<allVaults.length;i++){
            console.log("Vault",allVaults[i]);
            RiveraAutoCompoundingVaultV2Whitelisted vault=RiveraAutoCompoundingVaultV2Whitelisted(allVaults[i]);
            IStrategy strategy=IStrategy(vault.strategy());

            uint256 totalAssets=vault.totalAssets();
            console.log("Vault",allVaults[i],"totalAssets",totalAssets);
            uint256 tokenID=IStrategy(vault.strategy()).tokenID();
            console.log("Vault",allVaults[i],"tokenId",tokenID);
            uint256 balance=IStrategy(vault.strategy()).balanceOf();
            console.log("Vault",allVaults[i],"balance",balance);
            uint256 rewardBalance=strategy.rewardsAvailable();
            console.log("Vault",allVaults[i],"rewardBalance",rewardBalance);
        }
    }


}
