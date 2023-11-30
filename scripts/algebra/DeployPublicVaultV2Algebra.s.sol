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
    // address[] rewardToLp0AddressPath;
    // uint24[] rewardToLp0FeePath;
    // address[] rewardToLp1AddressPath;
    // uint24[] rewardToLp1FeePath;
    // address  rewardtoNativeFeed;
    address  assettoNativeFeed;
    address tickMathLib;
    address sqrtPriceMathLib;
    address liquidityMathLib;
    address safeCastLib;
    address liquidityAmountsLib;
    address fullMathLib;
    // string pendingReward;
}

struct FeeParams {
    uint256 withdrawFeeDecimals;//100
    uint256 withdrawFee;//0

    uint256 feeDecimals;//100
    uint256 protocolFee;//15
    uint256 fundManagerFee;//0
    uint256 partnerFee;//0
    address partner;//
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




contract DeployPublicVaultV2Algebra is Script {

    //factoru
    IRiveraVaultFactoryV2 _factory=IRiveraVaultFactoryV2(0x46ECf770a99d5d81056243deA22ecaB7271a43C7);
    address _stake = 0xF9a8400FA03316aF5f49654D43676f8A29B164DC;//mainnet
    address _lpToken0=0xB4B01216a5Bc8F1C8A33CD990A1239030E60C905;//mainnnet
    address _lpToken1=0xD102cE6A4dB07D247fcc28F366A623Df0938CA9E;//mainnnet
    address depositToken=_lpToken1;
    int24 _tickLower = -5640;
    int24 _tickUpper = 8160;
    string _tokenName="RIV-01-06-A75";
    string _tokenSymbol="RIV-01-06-A75";
    uint256 vaultTvlCap = 100000e18;
    uint256 _withdrawFeeDecimals=1000;
    uint256 _withdrawFee=3;
    uint256 _feeDecimals=100;
    uint256 _protocolFee=15;
    uint256 _fundManagerFee=0;
    uint256 _partnerFee=0;
    address _partner=0x961Ef0b358048D6E34BDD1acE00D72b37B9123D7;
    address  assettoNativeFeed=address(0);
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

    // string pendingReward="pendingFusionX";
    // address _reward = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    // //libraries
    address _tickMathLib =0x21071Cd83f468856dC269053e84284c5485917E1;
    address _sqrtPriceMathLib = 0xA9C3e24d94ef6003fB6064D3a7cdd40F87bA44de;
    address _liquidityMathLib = 0xA7B88e482d3C9d17A1b83bc3FbeB4DF72cB20478;
    address _safeCastLib = 0x3dbfDf42AEbb9aDfFDe4D8592D61b1de7bd7c26a;
    address _liquidityAmountsLib =0x672058B73396C78556fdddEc090202f066B98D71;
    address _fullMathLib = 0x46ECf770a99d5d81056243deA22ecaB7271a43C7;

    //usdt bnb pool



    uint256 stratUpdateDelay = 172800;
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
        console.log("Vault Factory",address(_factory));
        console.log("======================Deploy Vaults====================");
        console.log("create vault");
        RiveraVaultParams memory createVaultParamsFsxPool= RiveraVaultParams(
            depositToken,
            vaultTvlCap,
            stratUpdateDelay,
            _tokenName,
            _tokenSymbol,
            _tickLower,
            _tickUpper,
            _stake,
            // rewardToLp0AddressPath,
            // rewardToLp0FeePath,
            // rewardToLp1AddressPath,
            // rewardToLp1FeePath,
            // rewardtoNativeFeed,
            assettoNativeFeed,
            _tickMathLib,
            _sqrtPriceMathLib,
            _liquidityMathLib,
            _safeCastLib,
            _liquidityAmountsLib,
            _fullMathLib
            // pendingReward

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
        address vaultDeployed = _createVault(_factory,createVaultParamsFsxPool,feeParams);
        console.log("Vault",vaultDeployed);
        console.log("======================"); 
        vm.stopBroadcast(); 
        address[] memory vault=_factory.listAllVaults();
        console.log("all vaults",vault.length);
        console.log("======================Deposit in Vault====================");
        uint256 depositAmount1=IERC20(depositToken).balanceOf(_user3)/3;///vault 1 deposit amount
        vm.startBroadcast(_privateKey3);
        IERC20(depositToken).approve(vaultDeployed, depositAmount1);
        RiveraAutoCompoundingVaultV2Public(vaultDeployed).deposit(depositAmount1, _user3);
        console.log("deposited");
        vm.stopBroadcast();
        // vm.startBroadcast(_privateKey4);
        // IERC20(depositToken).approve(vaultDeployed, depositAmount1);
        // RiveraAutoCompoundingVaultV2Public(vaultDeployed).deposit(depositAmount1, _user4);
        // vm.stopBroadcast();
    }

    function _createVault(IRiveraVaultFactoryV2 factory,RiveraVaultParams memory createVaultParams,FeeParams memory feeParams) internal returns (address vaultAddress){
        
        vaultAddress =factory.createVault(createVaultParams,feeParams); 
    }
}

