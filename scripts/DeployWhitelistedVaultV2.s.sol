pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
// import "@rivera/factories/cake/vault/PancakeWhitelistedVaultFactoryV2.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
// import '@rivera/factories/cake/PancakeVaultCreationStruct.sol';

struct PancakeVaultParams {
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
    function createVault(PancakeVaultParams memory createVaultParams) external returns (address vault);

}




contract DeployWhitelistedVaultV2 is Script {

    //factoru
    IRiveraVaultFactoryV2 _factory=IRiveraVaultFactoryV2(0x6AB8c9590bD89cBF9DCC90d5efEC4F45D5d219be);


    address _cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //Adress of the CAKE ERC20 token on mainnet
    address _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //Address of wrapped version of BNB which is the native token of BSC
    address _usdt = 0x55d398326f99059fF775485246999027B3197955;
    address _bnbx=0x1bdd3Cf7F79cfB8EdbB955f20ad99211551BA275;
    address _ankrEth=0xe05A08226c49b636ACf99c40Da8DC6aF83CE5bB3;
    address _eth=0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address _whale = 0xD183F2BBF8b28d9fec8367cb06FE72B88778C86B;        //35 Mil whale 35e24
    address _whaleBnb=	0x8FA59693458289914dB0097F5F366d771B7a7C3F;
    address _whaleEth=0x34ea4138580435B5A521E460035edb19Df1938c1;
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



    string pendingReward="pendingCake";
    address _chef = 0x556B9306565093C855AEA9AE92A594704c2Cd59e;
    // address _reward = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    // //libraries
    address _tickMathLib = 0x21071Cd83f468856dC269053e84284c5485917E1;
    address _sqrtPriceMathLib = 0xA9C3e24d94ef6003fB6064D3a7cdd40F87bA44de;
    address _liquidityMathLib = 0xA7B88e482d3C9d17A1b83bc3FbeB4DF72cB20478;
    address _safeCastLib = 0x3dbfDf42AEbb9aDfFDe4D8592D61b1de7bd7c26a;
    address _liquidityAmountsLib = 0x672058B73396C78556fdddEc090202f066B98D71;
    address _fullMathLib = 0x46ECf770a99d5d81056243deA22ecaB7271a43C7;
    address  _rewardtoNativeFeed=0xcB23da9EA243f53194CBc2380A6d4d9bC046161f;
    // address  _assettoNativeFeed=0xD5c40f5144848Bd4EF08a9605d860e727b991513;


    //usdt bnb pool
    address[] _rewardToLp0AddressPath = [_cake, _usdt];
    uint24[] _rewardToLp0FeePath = [2500];
    address[] _rewardToLp1AddressPath = [_cake, _wbnb];
    uint24[] _rewardToLp1FeePath = [2500];
    address _stake = 0x36696169C63e42cd08ce11f5deeBbCeBae652050;
    address _assettoNativeFeedUsdtBnbPool=0xD5c40f5144848Bd4EF08a9605d860e727b991513;
    

    //BNBx / WBNB pool params
    address[] _rewardToLp0AddressPathBnbPool = [_cake,_wbnb, _bnbx];
    uint24[] _rewardToLp0FeePathBnbPool = [2500,500];
    address[] _rewardToLp1AddressPathBnbPool = [_cake, _wbnb];
    uint24[] _rewardToLp1FeePathBnbPool = [2500];
    address _stakeBnbPool=0x77B27c351B13Dc6a8A16Cc1d2E9D5e7F9873702E;//BNBx / WBNB
    address  _assettoNativeFeedBnbPool=address(0);


    //ETH / ankrETH pool params
    address[] _rewardToLp0AddressPathEthPool = [_cake,_wbnb, _eth];
    uint24[] _rewardToLp0FeePathEthPool = [2500,2500];
    address[] _rewardToLp1AddressPathEthPool = [_cake,_wbnb,_eth, _ankrEth];
    uint24[] _rewardToLp1FeePathEthPool = [2500,2500,500];
    address _stakeEthPool=0x61837a8a78F42dC6cfEd457c4eC1114F5e2d90f4;//BNBx / WBNB
    address  _assettoNativeFeedEthPool=0x63D407F32Aa72E63C7209ce1c2F5dA40b3AaE726;


    //common address
    address _router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    address _NonfungiblePositionManager =
        0x46A15B0b27311cedF172AB29E4f4766fbE7F4364;


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

        ///@dev Transfering usdt tokens from a whale to my accounts
        // vm.startPrank(_whale);
        // IERC20(_usdt).transfer(_user3, _maxUserBal);
        // IERC20(_usdt).transfer(_user4, _maxUserBal);
        // vm.stopPrank();

        // /@dev Transfering bnb tokens from a whale to my accounts
        // vm.startPrank(_whaleBnb);
        // IERC20(_wbnb).transfer(_user3, 1000e18);
        // IERC20(_wbnb).transfer(_user4, 1000e18);
        // vm.stopPrank();

        ///@dev Transfering eth tokens from a whale to my accounts
        // vm.startPrank(_whaleEth);
        // IERC20(_eth).transfer(_user3, 1000e18);
        // IERC20(_eth).transfer(_user4, 1000e18);
        // vm.stopPrank();

    }

    function run() public {

        vm.startBroadcast(_privateKey2);
        console.log("WhiteListed Vault Factory",address(_factory));

        console.log("======================Deploy Vaults====================");
        console.log("create vault of BNBx / WBNB pool");
        PancakeVaultParams memory createVaultParamsBnbPool= PancakeVaultParams(
            _wbnb,
            vaultTvlCap,
            stratUpdateDelay,
            "Riv-BNB-BNBX-Vault",
            "Riv-BNB-BNBX-Vault",
            100,
            1140,
            _stakeBnbPool,
            _rewardToLp0AddressPathBnbPool,
            _rewardToLp0FeePathBnbPool,
            _rewardToLp1AddressPathBnbPool,
            _rewardToLp1FeePathBnbPool,
            _rewardtoNativeFeed,
            _assettoNativeFeedBnbPool,
            _tickMathLib,
            _sqrtPriceMathLib,
            _liquidityMathLib,
            _safeCastLib,
            _liquidityAmountsLib,
            _fullMathLib,
            pendingReward
        );
        address vaultBnbPool = _createVault(_factory,createVaultParamsBnbPool);
        console.log("Vault BNBx / WBNB ",vaultBnbPool);

        console.log("======================");
        
        console.log("create vault of ETH / ankrETH  pool");

        PancakeVaultParams memory createVaultParamsEthPool= PancakeVaultParams(
            _eth,
            vaultTvlCap,
            stratUpdateDelay,
            "Riv-ETH-ankrETH-Vault",
            "Riv-ETH-ankrETH-Vault",
            -1610,
            -570,
            _stakeEthPool,
            _rewardToLp0AddressPathEthPool,
            _rewardToLp0FeePathEthPool,
            _rewardToLp1AddressPathEthPool,
            _rewardToLp1FeePathEthPool,
            _rewardtoNativeFeed,
            _assettoNativeFeedEthPool,
            _tickMathLib,
            _sqrtPriceMathLib,
            _liquidityMathLib,
            _safeCastLib,
            _liquidityAmountsLib,
            _fullMathLib,
            pendingReward
        );

        address vaultEthPool = _createVault(_factory,createVaultParamsEthPool);
        console.log("Vault ETH / ankrETH ",vaultEthPool);

        //whitelist the users
        RiveraAutoCompoundingVaultV2Whitelisted(vaultBnbPool).newWhitelist(_user3);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultBnbPool).newWhitelist(_user4);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultEthPool).newWhitelist(_user3);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultEthPool).newWhitelist(_user4);
        //whitelist the users from 5 to 8
        RiveraAutoCompoundingVaultV2Whitelisted(vaultBnbPool).newWhitelist(_user5);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultBnbPool).newWhitelist(_user6);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultBnbPool).newWhitelist(_user7);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultBnbPool).newWhitelist(_user8);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultBnbPool).newWhitelist(_user9);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultBnbPool).newWhitelist(_user10);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultEthPool).newWhitelist(_user5);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultEthPool).newWhitelist(_user6);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultEthPool).newWhitelist(_user7);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultEthPool).newWhitelist(_user8);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultEthPool).newWhitelist(_user9);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultEthPool).newWhitelist(_user10);

        uint256 depositAmount1=IERC20(_wbnb).balanceOf(_user3)/10;///vault 1 deposit amount
        uint256 depositAmount2=IERC20(_eth).balanceOf(_user3)/10;  ////vault 2 deposit amount
        
        vm.stopBroadcast();
        
        //get list of vaults
        address[] memory vault=_factory.listAllVaults();
        console.log("all vaults",vault.length);




        console.log("======================Deposit in Vaults====================");
        vm.startBroadcast(_privateKey3);
        //deposit in bnbvault
        // console2.log("wbnb balance");
        // console2.log(IERC20(_wbnb).balanceOf(_user3));
        IERC20(_wbnb).approve(vaultBnbPool, depositAmount1);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultBnbPool).deposit(depositAmount1, _user3);

        //deposit in ethvault
        IERC20(_eth).approve(vaultEthPool, depositAmount2);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultEthPool).deposit(depositAmount2, _user3);

        vm.stopBroadcast();

        vm.startBroadcast(_privateKey4);
        //deposit in bnbvaul
        IERC20(_wbnb).approve(vaultBnbPool, depositAmount1);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultBnbPool).deposit(depositAmount1, _user4);
        //deposit in ethvault
        IERC20(_eth).approve(vaultEthPool, depositAmount2);
        RiveraAutoCompoundingVaultV2Whitelisted(vaultEthPool).deposit(depositAmount2, _user4);
        vm.stopBroadcast();
        

    }

    function _createVault(IRiveraVaultFactoryV2 factory,PancakeVaultParams memory createVaultParams) internal returns (address vaultAddress){
        
        vaultAddress =factory.createVault(createVaultParams); 
    }
}

