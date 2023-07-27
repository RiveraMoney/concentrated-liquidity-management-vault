pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Public.sol";
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
    uint256 withdrawFeeDecimals;//100
    uint256 withdrawFee;//1

    uint256 feeDecimals;//1000
    uint256 protocolFee;//100
    uint256 fundManagerFee;//25
    uint256 partnerFee;//25
    address partner;//0xc60fE42A279A7F0A2D440BA1B3f3991088f01ce7
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




contract DeployPublicVaultLineaTestnet is Script {

    //factoru
    IRiveraVaultFactoryV2 _factory=IRiveraVaultFactoryV2(0x6F1138F2c619C54F87A4Cb95E42d3B275e155650);

    address _fsx=0x6dFB16bc471982f19DB32DEE9b6Fb40Db4503cBF;//testnet till we get mainnet address
    address _usdc=0xf56dc6695cF1f5c364eDEbC7Dc7077ac9B586068;//mainnnet
    address _weth=0x2C1b868d6596a18e32E61B901E4060C872647b6C;//mainnnet
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

    int24 _tickLower =-101020;
    int24 _tickUpper =-100300;
    string pendingReward="pendingCake";
    // address _reward = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    // //libraries
     address _tickMathLib =0xA9C3e24d94ef6003fB6064D3a7cdd40F87bA44de;
    address _sqrtPriceMathLib = 0x25ADF247aC836D35be924f4b701A0787A30d46a9;
    address _liquidityMathLib = 0xe931672196AB22B0c161b402B516f9eC33bD684c;
    address _safeCastLib = 0xA7B88e482d3C9d17A1b83bc3FbeB4DF72cB20478;
    address _liquidityAmountsLib =0x74C5E75798b33D38abeE64f7EC63698B7e0a10f1;
    address _fullMathLib = 0x672058B73396C78556fdddEc090202f066B98D71;

    //usdt bnb pool
    address _stake = 0xBd2d94d09AbaDc5084f278bd639Fbc9Af6A6bea0;//mainnet


    //FSX / _usdc pool params
    address[] rewardToLp0AddressPath = [_fsx,_weth,_usdc];
    uint24[] rewardToLp0FeePath = [2500,500];
    address[] rewardToLp1AddressPath = [_fsx, _usdc];
    uint24[] rewardToLp1FeePath = [2500];
    address  assettoNativeFeed=address(0);
    address rewardtoNativeFeed=address(0);
    // uint256 depositAmount1=5e6;///vault 1 deposit amount
    uint256 _withdrawFeeDecimals=100;
    uint256 _withdrawFee=1;

    uint256 _feeDecimals=1000;
    uint256 _protocolFee=100;
    uint256 _fundManagerFee=25;
    uint256 _partnerFee=25;
    address _partner=0xc60fE42A279A7F0A2D440BA1B3f3991088f01ce7 ;


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
        console.log("Public Vault Factory",address(_factory));
        console.log("======================Deploy Vaults====================");
        console.log("create vault of ETH / USDC pool");
        RiveraVaultParams memory createVaultParamsFsxPool= RiveraVaultParams(
            _usdc,
            vaultTvlCap,
            stratUpdateDelay,
            "Riv-ETH-USDC-YT-X",
            "Riv-ETH-USDC-YT-X",
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
            _withdrawFeeDecimals,
            _withdrawFee,
            _feeDecimals,
            _protocolFee,
            _fundManagerFee,
            _partnerFee,
            _partner
        );
        address vaultPool = _createVault(_factory,createVaultParamsFsxPool,feeParams);
        console.log("Vault FSX / _usdc ",vaultPool);
        console.log("======================"); 
        vm.stopBroadcast(); 
        address[] memory vault=_factory.listAllVaults();
        console.log("all vaults",vault.length);
        console.log("======================Deposit in Vault====================");
        vm.startBroadcast(_privateKey3);
        uint256 depositAmount1=IERC20(_usdc).balanceOf(_user3)/10;///vault 1 deposit amount
        // uint256 depositAmount1=15e6;///vault 1 deposit amount
        IERC20(_usdc).approve(vaultPool, depositAmount1);
        RiveraAutoCompoundingVaultV2Public(vaultPool).deposit(depositAmount1, _user3);
        vm.stopBroadcast();

    }

    function _createVault(IRiveraVaultFactoryV2 factory,RiveraVaultParams memory createVaultParams,FeeParams memory feeParams) internal returns (address vaultAddress){
        
        vaultAddress =factory.createVault(createVaultParams,feeParams); 
    }
}

