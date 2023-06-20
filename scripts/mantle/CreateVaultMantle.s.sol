pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
// import "@rivera/factories/cake/vault/PancakeWhitelistedVaultFactoryV2.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
// import '@rivera/factories/cake/PancakeVaultCreationStruct.sol';
import "@pancakeswap-v3-core/interfaces/IPancakeV3Pool.sol";


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
contract CreateVaultMantle is Script {
    address musdc=0xc92747b1e4Bd5F89BBB66bAE657268a5F4c4850C;
    address _fsx=0x6dFB16bc471982f19DB32DEE9b6Fb40Db4503cBF;
    address wbit=0x8734110e5e1dcF439c7F549db740E546fea82d66;
    address musdt=0xa9b72cCC9968aFeC98A96239B5AA48d828e8D827;
    address dai=0xB38E748dbCe79849b8298A1D206C8374EFc16DA7;

    //edit params according to vault to be deployed
    IRiveraVaultFactoryV2 _factory=IRiveraVaultFactoryV2(0xAd70E786D361E8EC1d6fE17A41629bB497C50A13);

    //vault 1 params
    address asset1=0xc92747b1e4Bd5F89BBB66bAE657268a5F4c4850C;
    uint256 vaultTvlCap1 = 10000e18;
    uint256 stratUpdateDelay1 = 172800;
    string tokenName1="Riv-DAI-MUSDC-Vault";
    string tokenSymbol1="Riv-DAI-MUSDC-Vault";
    int24 tickLower1=-6504;
    int24 tickUpper1=-6404;
    address stake1 = 0xD5E4DBEca6055535B6FBf4c4Bc51bDc104dE9EA6;
    address[] rewardToLp0AddressPath1 = [_fsx,dai];
    uint24[] rewardToLp0FeePath1 = [10000];
    address[] rewardToLp1AddressPath1 = [_fsx,musdc];
    uint24[] rewardToLp1FeePath1 = [10000];
    address rewardtoNativeFeed1=address(0);
    address assettoNativeFeed1=address(0);


    //libraries
    address tickMathLib =0x271d7594985F8CE8CB41c99761C5f42956ff6e5E;
    address sqrtPriceMathLib = 0x69e0778b9Ba7e795329Ec8971B1FE46fA783daF6;
    address liquidityMathLib = 0xE84a814B835E9F54e528Fb96205120E3bdA3f7d0;
    address safeCastLib = 0x070f86Ba8Af424e59e9FEA8509896BBD0b8dD0c5;
    address liquidityAmountsLib =0x00D4FDC04e86269cE7F4b1AcD985d5De0eA1C16d;
    address fullMathLib = 0x46b0D5C30537A800B12AF7a22D924F1636879965;

    string pendingReward="pendingFusionX";
    address _chef = 0x9316938Eaa09E71CBB1Bf713212A42beCBa2998F;
    address _reward = 0x6dFB16bc471982f19DB32DEE9b6Fb40Db4503cBF;
    address _router = 0xE3a68317a2F1c41E5B2efBCe2951088efB0Cf524;
    address _NonfungiblePositionManager =0x94705da51466F3Bb1E8c1591D71C09c9760f5F59;




    function run() public {
        uint256 ownerPrivateKey = 0xdff8d049b069f97d75a5021c3602165713192730bbca543e630d0b85385e49cb;
        // int24 tickSpacing = IPancakeV3Pool(stake).tickSpacing();
        // //console2 int24
        // console2.logInt(tickSpacing);
        // //conosle.log  lp0token and lp1token
        // console.log("lp0token",IPancakeV3Pool(stake).token0());
        // console.log("lp1token",IPancakeV3Pool(stake).token1());

        PancakeVaultParams[] memory vaults =new PancakeVaultParams[](1);
        vaults[0]=PancakeVaultParams(
            asset1,
            vaultTvlCap1,
            stratUpdateDelay1,
            tokenName1,
            tokenSymbol1,
            tickLower1,
            tickUpper1,
            stake1,
            rewardToLp0AddressPath1,
            rewardToLp0FeePath1,
            rewardToLp1AddressPath1,
            rewardToLp1FeePath1,
            rewardtoNativeFeed1,
            assettoNativeFeed1,
            tickMathLib,
            sqrtPriceMathLib,
            liquidityMathLib,
            safeCastLib,
            liquidityAmountsLib,
            fullMathLib,
            pendingReward
        );

        vm.startBroadcast(ownerPrivateKey);
        for(uint256 i=0;i<vaults.length;i++){
            address vault=_factory.createVault(vaults[i]);
            console.log("vault",vault);
        }
        vm.stopBroadcast();
    }
}
 