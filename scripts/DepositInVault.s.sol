pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "forge-std/StdUtils.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Private.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/strategies/cake/MarketNeutralV1.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/PancakePublicVaultFactoryV2.sol";
import "@rivera/PancakeWhitelistedVaultFactoryV2.sol";
import "@rivera/PancakePrivateVaultFactoryV2.sol";
import "@rivera/PancakeStratFactoryV2.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

contract DepositInVault is Script {
    address _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //Address of wrapped version of BNB which is the native token of BSC
    address _eth=0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address whiteListedVault;
    address _user3;
    address _user4;
    uint256 privateKey3;  
    uint256 privateKey4;  
    address _user2;  
    uint256 _maxUserBal = 15e24;
    address _whaleBnb=	0x8FA59693458289914dB0097F5F366d771B7a7C3F;
    uint256 depositAmount1=100e18;
    uint256 depositAmount2=10e18;



    function setUp() public {
        whiteListedVault =0x8Ff3b85b341fAd37417f77567624b08B5142fD5c;

        string memory seedPhrase = vm.readFile(".secret");
        uint256 _privateKey3 = vm.deriveKey(seedPhrase, 2);
        privateKey3 = _privateKey3;

        uint256 _privateKey4 = vm.deriveKey(seedPhrase, 3);
        privateKey4 = _privateKey4;
        ///user1 will be
        _user4 = vm.addr(_privateKey4);



    }

    function run() public {
        // vm.startPrank(_whaleBnb);
        // IERC20(_wbnb).transfer(_user3,100e18);
        // vm.stopPrank();

        // vm.deal(address(_wbnb),_user3,100e18);
        vm.startBroadcast(privateKey3);
        // vm.startPrank(_user3);
        console.log("balance of user",IERC20(_eth).balanceOf(_user3));
        //approval of vault
        IERC20(_eth).approve(whiteListedVault,depositAmount2);
        // console.log("approval of vault",IERC20(_eth).allowance(_user3,address(whiteListedVault)));

        //call deposit function of vault
        RiveraAutoCompoundingVaultV2Whitelisted(whiteListedVault).deposit(depositAmount2, _user3);
        uint256 totalassets=RiveraAutoCompoundingVaultV2Whitelisted(whiteListedVault).totalAssets();
        console.log("total assets",totalassets);
        // vm.stopPrank();
        vm.stopBroadcast();     

    }

}

