pragma solidity ^0.8.4;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "@rivera/strategies/cake/CakeLpStakingV1.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";

contract DeployRiveraV2VaultWithV1Strategy is Script {

    address _stake = 0xe68D05418A8d7969D9CA6761ad46F449629d928c;  //Mainnet address of the LP Pool you're deploying funds to. It is also the ERC20 token contract of the LP token.
    uint256 _poolId = 116;  //In Pancake swap every Liquidity Pool has a pool id. This is the pool id of the LP pool we're testing.
    address _chef = 0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652;   //Address of the pancake master chef v2 contract on BSC mainnet
    address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //Address of Pancake Swap router
    address _cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;   //Adress of the CAKE ERC20 token on mainnet
    address _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;   //Address of wrapped version of BNB which is the native token of BSC
    address _busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address _wom = 0xAD6742A35fB341A9Cc6ad674738Dd8da98b94Fb1;

    address[] _rewardToNativeRoute = new address[](2);
    address[] _rewardToLp0Route = new address[](3);
    address[] _rewardToLp1Route = new address[](2);

    uint256 stratUpdateDelay = 172800;
    uint256 vaultTvlCap = 10000e18;

    function setUp() public {
        _rewardToNativeRoute[0] = _cake;
        _rewardToNativeRoute[1] = _wbnb;

        _rewardToLp0Route[0] = _cake;
        _rewardToLp0Route[1] = _busd;
        _rewardToLp0Route[2] = _wom;

        _rewardToLp1Route[0] = _cake;
        _rewardToLp1Route[1] = _busd;
    }

    function run() public {
        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 0);
        vm.startBroadcast(privateKey);
        RiveraAutoCompoundingVaultV2Public vault = new RiveraAutoCompoundingVaultV2Public(_busd, "Riv-CAKE-USDT-Vault", "Riv-CAKE-USDT-Vault", stratUpdateDelay, vaultTvlCap);
        CommonAddresses memory _commonAddresses = CommonAddresses(address(vault), _router);
        CakePoolParams memory cakePoolParams = CakePoolParams(_stake, _poolId, _chef, _rewardToLp0Route, _rewardToLp1Route);
        CakeLpStakingV1 strategy = new CakeLpStakingV1(cakePoolParams, _commonAddresses);
        vault.init(IStrategy(address(strategy)));
        console2.logAddress(address(vault));

        vm.stopBroadcast();
    }
}
