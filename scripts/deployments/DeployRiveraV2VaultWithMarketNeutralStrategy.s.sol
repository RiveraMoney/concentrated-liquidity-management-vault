pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "@rivera/strategies/cake/MarketNeutralV1.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";

contract DeployRiveraV2VaultWithMarketNeutralStrategy is Script {
    address _cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //Adress of the CAKE ERC20 token on mainnet
    address _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //Address of wrapped version of BNB which is the native token of BSC
    address _usdt = 0x55d398326f99059fF775485246999027B3197955;

    //cakepool params
    bool _isTokenZeroDeposit = true;
    int24 _tickLower = -57260;
    int24 _tickUpper = -57170;
    address _stake = 0x36696169C63e42cd08ce11f5deeBbCeBae652050;
    address _chef = 0x556B9306565093C855AEA9AE92A594704c2Cd59e;
    address _reward = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    //libraries
    address _tickMathLib = ;
    address _sqrtPriceMathLib = ;
    address _liquidityMathLib = ;
    address _safeCastLib = ;
    address _liquidityAmountsLib = ;
    address _fullMathLib = ;
    uint24 _poolFee = 500;

    //common address
    address _router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    address _NonfungiblePositionManager =
        0x46A15B0b27311cedF172AB29E4f4766fbE7F4364;

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
            _chef,
            _reward,
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
        MarketNeutralV1 strategy = new MarketNeutralV1(
            cakePoolParams,
            _commonAddresses,
            shortParams
        );
        vault.init(IStrategy(address(strategy)));
        console2.logAddress(address(vault));

        vm.stopBroadcast();
    }
}
