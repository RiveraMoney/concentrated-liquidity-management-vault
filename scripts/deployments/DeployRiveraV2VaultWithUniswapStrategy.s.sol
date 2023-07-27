pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "@rivera/strategies/cake/MarketNeutralUniswap.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";

contract DeployRiveraV2VaultWithUniswapStrategy is Script {
    address _cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //Adress of the CAKE ERC20 token on mainnet
    address _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //Address of wrapped version of BNB which is the native token of BSC
    address _usdt = 0x55d398326f99059fF775485246999027B3197955;

    //cakepool params
    bool _isTokenZeroDeposit = true;
    int24 _tickLower = -57260;
    int24 _tickUpper = -57170;
    address _stake = 0x6fe9E9de56356F7eDBfcBB29FAB7cd69471a4869;
    //libraries
    address _tickMathLib = 0x6fe9E9de56356F7eDBfcBB29FAB7cd69471a4869;
    address _sqrtPriceMathLib = 0x6fe9E9de56356F7eDBfcBB29FAB7cd69471a4869;
    address _liquidityMathLib = 0x6fe9E9de56356F7eDBfcBB29FAB7cd69471a4869;
    address _safeCastLib = 0x6fe9E9de56356F7eDBfcBB29FAB7cd69471a4869;
    address _liquidityAmountsLib = 0x6fe9E9de56356F7eDBfcBB29FAB7cd69471a4869;
    address _fullMathLib = 0x6fe9E9de56356F7eDBfcBB29FAB7cd69471a4869;
    uint24 _poolFee = 500;

    //common address
    address _router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    address _NonfungiblePositionManager =
        0x7b8A01B39D58278b5DE7e48c8449c9f4F5170613;

    //short variables
    address _orderManager = 0xf584A17dF21Afd9de84F47842ECEAF6042b1Bb5b;
    address _indexTokenChainlink = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    uint256 _leverage = 3;

    uint256 stratUpdateDelay = 172800;
    uint256 vaultTvlCap = 10000e18;

    function setUp() public {
        // _rewardToNativeRoute[0] = _cake;
        // _rewardToNativeRoute[1] = _wbnb;
        // _rewardToLp0Route[0] = _cake;
        // _rewardToLp0Route[1] = _busd;
        // _rewardToLp0Route[2] = _wom;
        // _rewardToLp1Route[0] = _cake;
        // _rewardToLp1Route[1] = _busd;
    }

    function run() public {
        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 0);
        vm.startBroadcast(privateKey);
        RiveraAutoCompoundingVaultV2Public vault = new RiveraAutoCompoundingVaultV2Public(
                _usdt,
                "Riv-CAKE-USDT-Vault",
                "Riv-CAKE-USDT-Vault",
                stratUpdateDelay,
                vaultTvlCap
            );
        CommonAddresses memory _commonAddresses = CommonAddresses(
            address(vault),
            _router,
            _NonfungiblePositionManager
        );
        CakePoolParams memory cakePoolParams = CakePoolParams(
            _isTokenZeroDeposit,
            _tickLower,
            _tickUpper,
            _stake,
            _tickMathLib,
            _sqrtPriceMathLib,
            _liquidityMathLib,
            _safeCastLib,
            _liquidityAmountsLib,
            _fullMathLib,
            _poolFee
        );
        ShortParams memory shortParams = ShortParams(
            _orderManager,
            _indexTokenChainlink,
            _leverage
        );
        MarketNeutralUniswap strategy = new MarketNeutralUniswap(
            cakePoolParams,
            _commonAddresses,
            shortParams
        );
        vault.init(IStrategy(address(strategy)));
        console2.logAddress(address(vault));

        vm.stopBroadcast();
    }
}
