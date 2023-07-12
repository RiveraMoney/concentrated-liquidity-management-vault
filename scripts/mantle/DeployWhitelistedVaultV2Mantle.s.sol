pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
// import "@rivera/factories/staking/vault/RiveraConcLiqStakingWhiLisVaultFactory.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
// import '@rivera/factories/staking/RiveraLpStakingVaultCreationStruct.sol';

struct RiveraVaultParams {
    address asset;
    uint256 totalTvlCap;
    uint256 approvalDelay;
    string tokenName;
    string tokenSymbol;
    int24 tickLower;
    int24 tickUpper;
    address stake;
    address[] rewardToLp0AddressPath;
    uint24[] rewardToLp0FeePath;
    address[] rewardToLp1AddressPath;
    uint24[] rewardToLp1FeePath;
    address  rewardtoNativeFeed;
    address  assettoNativeFeed;
    address tickMathLib;
    address sqrtPriceMathLib;
    address liquidityMathLib;
    address safeCastLib;
    address liquidityAmountsLib;
    address fullMathLib;
    string pendingReward;
}

struct FeeParams {
    uint256 withdrawFeeDecimals;
    uint256 withdrawFee;

    uint256 feeDecimals;
    uint256 protocolFee;
    uint256 fundManagerFee;
    uint256 partnerFee;
    address partner;
}


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
    function createVault(RiveraVaultParams memory createVaultParams,FeeParams memory feePArams) external returns (address vault);

}




contract DeployWhitelistedVaultV2Mantle is Script {

    //factoru
    IRiveraVaultFactoryV2 _factory=IRiveraVaultFactoryV2(0xC6464Dbb1dda6479d5402E955beEf5Fb81c7dA43);

    address _fsx=0x6dFB16bc471982f19DB32DEE9b6Fb40Db4503cBF;
    address wbit=0x8734110e5e1dcF439c7F549db740E546fea82d66;
    address musdt=0xa9b72cCC9968aFeC98A96239B5AA48d828e8D827;
    address whaleFsx=0x3EB827c42055450FC3999567556154ABb105F989;
    uint256 _maxUserBal = 15e24;
    address _user1;
    address _user2;
    address _user3;  
    address _user4;
    address _user5;
    address _user6;
    address _user7;
    address _user8;
    address _user9;
    address _user10;
    uint256 _privateKey1;
    uint256 _privateKey2;
    uint256 _privateKey3;
    uint256 _privateKey4;

    int24 _tickLower = 46600;
    int24 _tickUpper = 48700;
    string pendingReward="pendingFusionX";
    // address _reward = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    // //libraries
     address _tickMathLib =0x271d7594985F8CE8CB41c99761C5f42956ff6e5E;
    address _sqrtPriceMathLib = 0x69e0778b9Ba7e795329Ec8971B1FE46fA783daF6;
    address _liquidityMathLib = 0xE84a814B835E9F54e528Fb96205120E3bdA3f7d0;
    address _safeCastLib = 0x070f86Ba8Af424e59e9FEA8509896BBD0b8dD0c5;
    address _liquidityAmountsLib =0x00D4FDC04e86269cE7F4b1AcD985d5De0eA1C16d;
    address _fullMathLib = 0x46b0D5C30537A800B12AF7a22D924F1636879965;

    //usdt bnb pool
    address _stake = 0x30F63e60Ab33B05f3baFf97E5A35010De6F4Ea9D;


    //FSX / WBIT pool params
    address[] rewardToLp0AddressPath = [_fsx,musdt,wbit];
    uint24[] rewardToLp0FeePath = [2500,500];
    address[] rewardToLp1AddressPath = [_fsx, wbit];
    uint24[] rewardToLp1FeePath = [2500];
    address  assettoNativeFeed=address(0);
    address rewardtoNativeFeed=address(0);
    uint256 depositAmount1=2e18;///vault 1 deposit amount


    uint256 stratUpdateDelay = 172800;
    uint256 vaultTvlCap = 10000e18;
    VaultType _vaultType;

    function setUp() public {
        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey1 = vm.deriveKey(seedPhrase, 0);      //[key1, key2, ...] = vm.deriveKeys(seedPhrase, 0, 10); 
        _privateKey1=privateKey1;
        ///user1 will be
        _user1 = vm.addr(privateKey1);
        uint256 privateKey2 = vm.deriveKey(seedPhrase, 1);
        _privateKey2=privateKey2;
        ///user2 will be
        _user2 = vm.addr(privateKey2);

        uint256 privateKey3 = vm.deriveKey(seedPhrase, 2);
        _privateKey3=privateKey3;
        ///user3 will be
        _user3 = vm.addr(privateKey3);

        uint256 privateKey4 = vm.deriveKey(seedPhrase,3);
        _privateKey4=privateKey4;
        _user4 =vm.addr(privateKey4);

        uint256 privateKey5 = vm.deriveKey(seedPhrase,4);
        _user5 =vm.addr(privateKey5);

        uint256 privateKey6 = vm.deriveKey(seedPhrase,5);
        _user6 =vm.addr(privateKey6);

        uint256 privateKey7 = vm.deriveKey(seedPhrase,6);
        _user7 =vm.addr(privateKey7);

        uint256 privateKey8 = vm.deriveKey(seedPhrase,7);
        _user8 =vm.addr(privateKey8);

        uint256 privateKey9 = vm.deriveKey(seedPhrase,8);
        _user9 =vm.addr(privateKey9);

        uint256 privateKey10 = vm.deriveKey(seedPhrase,9);
        _user10 =vm.addr(privateKey10);

        console.log("user1",_user1);
        console.log("user2",_user2);
        console.log("user3",_user3);
        console.log("user4",_user4);

    }

    function run() public {

        vm.startBroadcast(_privateKey2);
        console.log("WhiteListed Vault Factory",address(_factory));
        console.log("======================Deploy Vaults====================");
        console.log("create vault of FSX / WBIT pool");
        RiveraVaultParams memory createVaultParamsFsxPool= RiveraVaultParams(
            wbit,
            vaultTvlCap,
            stratUpdateDelay,
            "Riv-FSX-WBIT-Vault",
            "Riv-FSX-WBIT-Vault",
            _tickLower,
            _tickUpper,
            _stake,
            rewardToLp0AddressPath,
            rewardToLp0FeePath,
            rewardToLp1AddressPath,
            rewardToLp1FeePath,
            rewardtoNativeFeed,
            assettoNativeFeed,
            _tickMathLib,
            _sqrtPriceMathLib,
            _liquidityMathLib,
            _safeCastLib,
            _liquidityAmountsLib,
            _fullMathLib,
            pendingReward

        );
        FeeParams memory feeParams = FeeParams(
            1,1,1,1,1,1,_user1
        );
        address vaultFsxPool = _createVault(_factory,createVaultParamsFsxPool,feeParams);
        console.log("Vault FSX / WBIT ",vaultFsxPool);
        console.log("======================");
        //whitelist the users
        RiveraAutoCompoundingVaultV2Whitelisted(vaultFsxPool).newWhitelist(_user3);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultFsxPool).newWhitelist(_user4);
        //whitelist the users from 5 to 8
        RiveraAutoCompoundingVaultV2Whitelisted(vaultFsxPool).newWhitelist(_user5);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultFsxPool).newWhitelist(_user6);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultFsxPool).newWhitelist(_user7);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultFsxPool).newWhitelist(_user8);     
        RiveraAutoCompoundingVaultV2Whitelisted(vaultFsxPool).newWhitelist(_user9);     
        RiveraAutoCompoundingVaultV2Whitelisted(vaultFsxPool).newWhitelist(_user10);     
        vm.stopBroadcast(); 
        address[] memory vault=_factory.listAllVaults();
        console.log("all vaults",vault.length);
        console.log("======================Deposit in Vault====================");
        vm.startBroadcast(_privateKey3);
        IERC20(wbit).approve(vaultFsxPool, depositAmount1);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultFsxPool).deposit(depositAmount1, _user3);
        vm.stopBroadcast();
        vm.startBroadcast(_privateKey4);
        IERC20(wbit).approve(vaultFsxPool, depositAmount1);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultFsxPool).deposit(depositAmount1, _user4);
        vm.stopBroadcast();

    }

    function _createVault(IRiveraVaultFactoryV2 factory,RiveraVaultParams memory createVaultParams,FeeParams memory feeParams) internal returns (address vaultAddress){
        
        vaultAddress =factory.createVault(createVaultParams,feeParams); 
    }
}

