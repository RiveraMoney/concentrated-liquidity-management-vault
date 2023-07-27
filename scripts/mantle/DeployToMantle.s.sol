pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "@rivera/strategies/cake/CakeLpStakingV2.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";

contract DeployToMantle is Script {
    address _user2;

    address _fsx=0x6dFB16bc471982f19DB32DEE9b6Fb40Db4503cBF;
    address wbit=0x8734110e5e1dcF439c7F549db740E546fea82d66;
    address musdt=0xa9b72cCC9968aFeC98A96239B5AA48d828e8D827;
    address whaleFsx=0x3EB827c42055450FC3999567556154ABb105F989;

    //cakepool params
    int24 _tickLower = 46600 ;
    int24 _tickUpper = 48700;
    address _stake = 0x30F63e60Ab33B05f3baFf97E5A35010De6F4Ea9D;
    address _chef = 0x9316938Eaa09E71CBB1Bf713212A42beCBa2998F;
    address _reward = 0x6dFB16bc471982f19DB32DEE9b6Fb40Db4503cBF;
    //libraries
    address _tickMathLib =0x271d7594985F8CE8CB41c99761C5f42956ff6e5E;
    address _sqrtPriceMathLib = 0x69e0778b9Ba7e795329Ec8971B1FE46fA783daF6;
    address _liquidityMathLib = 0xE84a814B835E9F54e528Fb96205120E3bdA3f7d0;
    address _safeCastLib = 0x070f86Ba8Af424e59e9FEA8509896BBD0b8dD0c5;
    address _liquidityAmountsLib =0x00D4FDC04e86269cE7F4b1AcD985d5De0eA1C16d;
    address _fullMathLib = 0x46b0D5C30537A800B12AF7a22D924F1636879965;
    uint24 _poolFee = 2500;

    //common address
    address _router = 0xE3a68317a2F1c41E5B2efBCe2951088efB0Cf524;
    address _NonfungiblePositionManager =
        0x94705da51466F3Bb1E8c1591D71C09c9760f5F59;

    address[] rewardToLp0AddressPath = [_fsx,musdt, wbit];
    uint24[] rewardToLp0FeePath = [2500,500];
    address[] rewardToLp1AddressPath = [_fsx, wbit];
    uint24[] rewardToLp1FeePath = [2500];
    address  assettoNativeFeed=address(0);
    address rewardtoNativeFeed=address(0);

    //short variables
    uint256 stratUpdateDelay = 172800;
    uint256 vaultTvlCap = 10000e18;

    function setUp() public {
    }

    function run() public {
        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 1);
        _user2=vm.addr(privateKey);
        vm.startBroadcast(privateKey);
        RiveraAutoCompoundingVaultV2Public vault = new RiveraAutoCompoundingVaultV2Public(
                wbit,
                "Riv-FSX-WBIT-Vault",
                "Riv-FSX-WBIT-Vault",
                stratUpdateDelay,
                vaultTvlCap
            );
        CommonAddresses memory _commonAddresses = CommonAddresses(
            address(vault),
            _router,
            _NonfungiblePositionManager
        );
        CakePoolParams memory cakePoolParams = CakePoolParams(
            _tickLower,
            _tickUpper,
            _stake,
            _chef,
            _reward,
            _tickMathLib,
            _sqrtPriceMathLib,
            _liquidityMathLib,
            _safeCastLib,
            _liquidityAmountsLib,
            _fullMathLib,
            rewardToLp0AddressPath,
            rewardToLp0FeePath,
            rewardToLp1AddressPath,
            rewardToLp1FeePath,
            rewardtoNativeFeed,
            assettoNativeFeed
        );
        CakeLpStakingV2 strategy = new CakeLpStakingV2(
        );
        strategy.init(
            cakePoolParams,
            _commonAddresses
        );
        vault.init(IStrategy(address(strategy)));
        console2.logAddress(address(strategy));
        console2.logAddress(address(vault));
        IERC20(wbit).approve(address(vault), 10e18);
        vault.deposit(10e18, _user2);
        uint256 totalAssets = vault.totalAssets();
        console.log("totalAssets", totalAssets);
        //try to withdraw
        vault.withdraw(5e18, _user2, _user2);
        totalAssets = vault.totalAssets();
        console.log("totalAssets", totalAssets);
        vm.stopBroadcast();
    }
}
 