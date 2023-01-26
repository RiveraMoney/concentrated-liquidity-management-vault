pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../src/strategies/cake/CakeLpStakingV1.sol";
import "../../../src/strategies/common/interfaces/IStrategy.sol";
import "../../../src/vaults/RiveraAutoCompoundingVaultV1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

///@dev
///As there is dependency on Cake swap protocol. Replicating the protocol deployment on separately is difficult. Hence we would test on main net fork of BSC.
///The addresses used below must also be mainnet addresses.

contract CakeLpStakingInitializationV1Test is Test {
    CakeLpStakingV1 strategy;
    RiveraAutoCompoundingVaultV1 vault;

    ///@dev Required addresses from mainnet
    ///@notice Currrent addresses are for the BUSD-WOM pool
    //TODO: move these address configurations to an external file and keep it editable and configurable
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

    ///@dev Vault Params
    ///@notice Can be configured according to preference
    string rivTokenName = "Riv CakeV2 WOM-BUSD";
    string rivTokenSymbol = "rivCakeV2WOM-BUD";
    uint256 stratUpdateDelay = 21600;

    ///@dev Users Setup
    address _user = 0xbA79a22A4b8018caFDC24201ab934c9AdF6903d7;
    address _manager = 0x2fdD10fa2CA4Dfb87c52e2c4F0488120eDD61B6B;
    address _other = 0xF18Bb60E7Bd9BD65B61C57b9Dd89cfEb774274a1;
    address _whale = 0x14bA0D857C496C03A8c8D5Fcc6c92d30Df804775;
    address _factory = 0x4B16c5dE96EB2117bBE5fd171E4d203624B014aa;

    function setUp() public {
        ///@dev creating the routes
        _rewardToNativeRoute[0] = _cake;
        _rewardToNativeRoute[1] = _wbnb;

        _rewardToLp0Route[0] = _cake;
        _rewardToLp0Route[1] = _busd;
        _rewardToLp0Route[2] = _wom;

        _rewardToLp1Route[0] = _cake;
        _rewardToLp1Route[1] = _busd;

        ///@dev all deployments will be made by the user
        vm.startPrank(_user);

        ///@dev Initializing the vault with invalid strategy
        vault = new RiveraAutoCompoundingVaultV1(rivTokenName, rivTokenSymbol, stratUpdateDelay);

        ///@dev Initializing the strategy
        CommonAddresses memory _commonAddresses = CommonAddresses(address(vault), _router);
        CakePoolParams memory cakePoolParams = CakePoolParams(_stake, _poolId, _chef, _rewardToLp0Route, _rewardToLp1Route);
        strategy = new CakeLpStakingV1(cakePoolParams, _commonAddresses);
        vm.stopPrank();

        ///@dev Transfering LP tokens from a whale to my accounts
        vm.startPrank(_whale);
        IERC20(_stake).transfer(_user, 1e22);
        IERC20(_stake).transfer(_other, 1e22);
        vm.stopPrank();

    }

    ///@notice tests for init function

    function test_InitializationFromFactoryContractFirstTime() public {
        vm.prank(_factory);
        vault.init(IStrategy(address(strategy)));
        assertEq(address(vault.strategy()), address(strategy));
    }

}