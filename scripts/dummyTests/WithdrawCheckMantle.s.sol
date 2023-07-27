pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/factories/cake/PancakeStratFactoryV2.sol";

interface IRiveraVaultFactoryV2
 {
    event VaultCreated(address indexed user, address indexed stake, address vault);

    function allVaults(uint) external view returns (address vault);
    function listAllVaults() external view returns (address[] memory);
    function createVault(PancakeVaultParams memory createVaultParams) external returns (address vault);

}
contract WithdrawCheckMantle is Script {
    // address _vault=0x4Eb4378F1fFe76e2F91074FA36cEF04261BB50F5;//fsx-wbit
    address _vault=0xc9742A05EE372Ce75b46E38fc6B42Cf3c83848A3;//musdc-dai 
    address asset;

    function run() public {

        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 2);
        address user=vm.addr(privateKey);


        vm.startPrank(user);
        // vm.startBroadcast(privateKey);
        RiveraAutoCompoundingVaultV2Whitelisted vault=RiveraAutoCompoundingVaultV2Whitelisted(_vault);
        IStrategy strategy=vault.strategy();
        asset=vault.asset();
        
        uint256 assetBeforeDeposit=IERC20(asset).balanceOf(user);
        console.log("assetBeforeDeposit",assetBeforeDeposit);
        uint256 depositAmount=assetBeforeDeposit/3;
        console.log("depositAmount",depositAmount);
        IERC20(asset).approve(_vault, depositAmount);
        RiveraAutoCompoundingVaultV2Whitelisted(_vault).deposit(depositAmount, user);

        //assetd balance of user
        uint256 assetAfterDeposit=IERC20(asset).balanceOf(user);
        console.log("assetAfterDeposit",assetAfterDeposit);

        uint256 maxWithdrawableAmount=vault.maxWithdraw(user);
        console.log("maxWithdrawableAmount",maxWithdrawableAmount);

        vault.withdraw(maxWithdrawableAmount,user,user);

        uint256 assetAfter=IERC20(asset).balanceOf(user);
        console.log("assetAfterwithdraw",assetAfter);
        vm.stopPrank();
        // vm.stopBroadcast();

    }

}
