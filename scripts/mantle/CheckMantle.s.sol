pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";

interface IRiveraVaultFactoryV2
 {
    event VaultCreated(address indexed user, address indexed stake, address vault);

    function allVaults(uint) external view returns (address vault);
    function listAllVaults() external view returns (address[] memory);

}



contract CheckMantle is Script {
  
    address _chef = 0x9316938Eaa09E71CBB1Bf713212A42beCBa2998F;
    address _router = 0xE3a68317a2F1c41E5B2efBCe2951088efB0Cf524;
    address _NonfungiblePositionManager = 0x94705da51466F3Bb1E8c1591D71C09c9760f5F59;
    address vaultFactory=0xEbe79B0eF31aFB3c893e94FE8EbF11D5CB2231d5 ;

    function run() public {

        address [] memory allVaults=IRiveraVaultFactoryV2(vaultFactory).listAllVaults();
        for(uint i=0;i<allVaults.length;i++){
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
            uint256 lpRewardAvailable=strategy.lpRewardsAvailable();
            console.log("Vault",allVaults[i],"lpRewardsAvailable",lpRewardAvailable);

        }
    }


}
