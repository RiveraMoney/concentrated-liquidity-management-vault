pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/strategies/cake/CakeLpStakingV1.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV1.sol";
import "../src/PancakeVaultFactoryV1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

///@dev
///As there is dependency on Cake swap protocol. Replicating the protocol deployment on separately is difficult. Hence we would test on main net fork of BSC.
///The addresses used below must also be mainnet addresses.

contract PancakeVaultFactoryV1Test is Test {

    using Address for address;

    //Events
    event StratHarvest(
        address indexed harvester,
        uint256 stakeHarvested,
        uint256 tvl
    );
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);

    event NewStratCandidate(address implementation);
    event UpgradeStrat(address implementation);

    event VaultCreated(address indexed user, address indexed lpPool, uint256 indexed poolId, address vault);

    ///@dev Required addresses from mainnet
    ///@notice Currrent addresses are for the BUSD-WOM pool
    //TODO: move these address configurations to an external file and keep it editable and configurable
    address _stake = 0xe68D05418A8d7969D9CA6761ad46F449629d928c;  //Mainnet address of the LP Pool you're deploying funds to. It is also the ERC20 token contract of the LP token.
    uint256 _poolId = 116;  //In Pancake swap every Liquidity Pool has a pool id. This is the pool id of the LP pool we're testing.
    address _chef = 0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652;   //Address of the pancake master chef v2 contract on BSC mainnet
    address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //Address of Pancake Swap router
    address _pancakeFactory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address _cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;   //Adress of the CAKE ERC20 token on mainnet
    address _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;   //Address of wrapped version of BNB which is the native token of BSC
    address _busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address _wom = 0xAD6742A35fB341A9Cc6ad674738Dd8da98b94Fb1;

    address _stake2 = 0x89c68051543Fa135B31c2CE7BD8Cdf392345FF01;  //Mainnet address of the LP Pool you're deploying funds to. It is also the ERC20 token contract of the LP token.
    uint256 _poolId2 = 117;  //In Pancake swap every Liquidity Pool has a pool id. This is the pool id of the LP pool we're testing.
    address _spin = 0x6AA217312960A21aDbde1478DC8cBCf828110A67;

    address[] _rewardToNativeRoute = new address[](2);
    address[] _rewardToLp0Route = new address[](3);
    address[] _rewardToLp1Route = new address[](2);

    address[] _rewardToLp0Route2 = new address[](3);
    address[] _rewardToLp1Route2 = new address[](2);

    ///@dev Vault Params
    ///@notice Can be configured according to preference
    string rivTokenName = "Riv CakeV2 WOM-BUSD";
    string rivTokenSymbol = "rivCakeV2WOM-BUD";
    uint256 stratUpdateDelay = 21600;
    string rivTokenName2 = "Riv CakeV2 SPIN-BNB";
    string rivTokenSymbol2 = "rivCakeV2SPIN-BNB";

    string pendingRewardsFunctionName = "pendingCake";

    ///@dev Users Setup
    address _user = 0xbA79a22A4b8018caFDC24201ab934c9AdF6903d7;
    address _manager = 0x2fdD10fa2CA4Dfb87c52e2c4F0488120eDD61B6B;
    address _other = 0xF18Bb60E7Bd9BD65B61C57b9Dd89cfEb774274a1;
    address _whale = 0x14bA0D857C496C03A8c8D5Fcc6c92d30Df804775;
    address _whale2 = 0xcf9EA608Bfb76d14137A41650C17f69F9B8777D1;
    address _busdWhale = 0x4B16c5dE96EB2117bBE5fd171E4d203624B014aa;

    PancakeVaultFactoryV1 factory;

    function setUp() public {
        ///@dev creating the routes
        _rewardToNativeRoute[0] = _cake;
        _rewardToNativeRoute[1] = _wbnb;

        _rewardToLp0Route[0] = _cake;
        _rewardToLp0Route[1] = _busd;
        _rewardToLp0Route[2] = _wom;

        _rewardToLp1Route[0] = _cake;
        _rewardToLp1Route[1] = _busd;

        _rewardToLp1Route2[0] = _cake;
        _rewardToLp1Route2[1] = _wbnb;

        _rewardToLp0Route2[0] = _cake;
        _rewardToLp0Route2[1] = _busd;
        _rewardToLp0Route2[2] = _spin;

        ///@dev Transfering LP tokens from a whale to my accounts
        vm.startPrank(_whale);
        IERC20(_stake).transfer(_user, 1e22);
        IERC20(_stake).transfer(_other, 1e22);
        vm.stopPrank();

        vm.startPrank(_whale2);
        IERC20(_stake2).transfer(_user, 50*1e18);
        IERC20(_stake2).transfer(_other, 50*1e18);
        vm.stopPrank();

        vm.prank(_busdWhale);
        IERC20(_busd).transfer(_user, 1e22);

        factory = new PancakeVaultFactoryV1(_chef, _router, _pancakeFactory);

    }

    function test_CreateVaultWithCorrectParameters() public {
        vm.prank(_user);
        CreateVaultParams memory createVaultParams = CreateVaultParams(_poolId, stratUpdateDelay, _rewardToLp0Route, _rewardToLp1Route, rivTokenName, rivTokenSymbol, pendingRewardsFunctionName);
        vm.expectEmit(true, true, true, false);
        emit VaultCreated(_user, _stake, _poolId, address(0));
        address vaultAddress = factory.createVault(createVaultParams);

        // assertEq(factory.getVault(_user, _stake, _poolId), vaultAddress);
        assertEq(factory.allVaults(0), vaultAddress);
        
        assertTrue(Address.isContract(vaultAddress));

        RiveraAutoCompoundingVaultV1 vault = RiveraAutoCompoundingVaultV1(vaultAddress);
        assertEq(address(vault.stake()), _stake);
        assertEq(vault.approvalDelay(), stratUpdateDelay);
        assertEq(vault.name(), rivTokenName);
        assertEq(vault.symbol(), rivTokenSymbol);
        assertEq(vault.owner(), _user);
        assertTrue(Address.isContract(address(vault.strategy())));

        assertEq(vault.strategy().poolId(), _poolId);
        assertEq(address(vault.strategy().reward()), _cake);
        assertEq(address(vault.strategy().lpToken0()), _wom);
        assertEq(address(vault.strategy().lpToken1()), _busd);
        assertEq(address(vault.strategy().chef()), _chef);
        assertEq(vault.strategy().rewardToLp0Route(0), _rewardToLp0Route[0]);
        assertEq(vault.strategy().rewardToLp0Route(1), _rewardToLp0Route[1]);
        assertEq(vault.strategy().rewardToLp0Route(2), _rewardToLp0Route[2]);
        assertEq(vault.strategy().rewardToLp1Route(0), _rewardToLp1Route[0]);
        assertEq(vault.strategy().rewardToLp1Route(1), _rewardToLp1Route[1]);
        assertEq(vault.strategy().owner(), _user);

    }

    function test_CreateVaultRevertIfVaultAlreadyExists() public {
        vm.prank(_user);
        CreateVaultParams memory createVaultParams = CreateVaultParams(_poolId, stratUpdateDelay, _rewardToLp0Route, _rewardToLp1Route, rivTokenName, rivTokenSymbol, pendingRewardsFunctionName);
        vm.expectEmit(true, true, true, false);
        emit VaultCreated(_user, _stake, _poolId, address(0));
        address vaultAddress = factory.createVault(createVaultParams);

        // assertEq(factory.getVault(_user, _stake, _poolId), vaultAddress);
        assertEq(factory.allVaults(0), vaultAddress);
        
        assertTrue(Address.isContract(vaultAddress));

        RiveraAutoCompoundingVaultV1 vault = RiveraAutoCompoundingVaultV1(vaultAddress);
        assertEq(address(vault.stake()), _stake);
        assertEq(vault.approvalDelay(), stratUpdateDelay);
        assertEq(vault.name(), rivTokenName);
        assertEq(vault.symbol(), rivTokenSymbol);
        assertTrue(Address.isContract(address(vault.strategy())));

        assertEq(vault.strategy().poolId(), _poolId);
        assertEq(address(vault.strategy().reward()), _cake);
        assertEq(address(vault.strategy().lpToken0()), _wom);
        assertEq(address(vault.strategy().lpToken1()), _busd);
        assertEq(address(vault.strategy().chef()), _chef);
        assertEq(vault.strategy().rewardToLp0Route(0), _rewardToLp0Route[0]);
        assertEq(vault.strategy().rewardToLp0Route(1), _rewardToLp0Route[1]);
        assertEq(vault.strategy().rewardToLp0Route(2), _rewardToLp0Route[2]);
        assertEq(vault.strategy().rewardToLp1Route(0), _rewardToLp1Route[0]);
        assertEq(vault.strategy().rewardToLp1Route(1), _rewardToLp1Route[1]);

        vm.prank(_user);
        vm.expectRevert('VAULT_EXISTS');
        factory.createVault(createVaultParams);

    }

    function test_CreateVaultRevertsWhenInvalidLpPoolIdGiven() public {
        vm.prank(_user);
        CreateVaultParams memory createVaultParams = CreateVaultParams(200, stratUpdateDelay, _rewardToLp0Route, _rewardToLp1Route, rivTokenName, rivTokenSymbol, pendingRewardsFunctionName);
        vm.expectRevert('INVALID_POOL_ID');
        factory.createVault(createVaultParams);

    }

    function test_CreateVaultRevertsWhenInvalidLpPoolToken0Given() public {
        _rewardToLp0Route[2] = address(0);
        vm.prank(_user);
        CreateVaultParams memory createVaultParams = CreateVaultParams(_poolId, stratUpdateDelay, _rewardToLp0Route, _rewardToLp1Route, rivTokenName, rivTokenSymbol, pendingRewardsFunctionName);
        // vm.expectRevert('RiveraPanCakeVaultFactoryV1: LP_TOKEN0_ZERO_ADDRESS'); Reverts with INVALID pool error message because there is no pool with zero address in pancake swap
        vm.expectRevert('LP_TOKEN0_ZERO_ADDRESS');
        factory.createVault(createVaultParams);

    }

    function test_CreateVaultShouldNotBeInitializableAfterDeployment() public {
        vm.prank(_user);
        CreateVaultParams memory createVaultParams = CreateVaultParams(_poolId, stratUpdateDelay, _rewardToLp0Route, _rewardToLp1Route, rivTokenName, rivTokenSymbol, pendingRewardsFunctionName);
        vm.expectEmit(true, true, true, false);
        emit VaultCreated(_user, _stake, _poolId, address(0));
        address vaultAddress = factory.createVault(createVaultParams);

        // assertEq(factory.getVault(_user, _stake, _poolId), vaultAddress);
        assertEq(factory.allVaults(0), vaultAddress);
        
        assertTrue(Address.isContract(vaultAddress));

        RiveraAutoCompoundingVaultV1 vault = RiveraAutoCompoundingVaultV1(vaultAddress);
        IStrategy strat = vault.strategy();
        vm.expectRevert("Initializable: contract is already initialized");
        vault.init(strat);

    }

    function test_OtherUserCreateVaultWithSameParameters() public {
        vm.prank(_user);
        CreateVaultParams memory createVaultParams = CreateVaultParams(_poolId, stratUpdateDelay, _rewardToLp0Route, _rewardToLp1Route, rivTokenName, rivTokenSymbol, pendingRewardsFunctionName);
        vm.expectEmit(true, true, true, false);
        emit VaultCreated(_user, _stake, _poolId, address(0));
        address vaultAddress = factory.createVault(createVaultParams);

        // assertEq(factory.getVault(_user, _stake, _poolId), vaultAddress);
        assertEq(factory.allVaults(0), vaultAddress);
        
        assertTrue(Address.isContract(vaultAddress));

        RiveraAutoCompoundingVaultV1 vault = RiveraAutoCompoundingVaultV1(vaultAddress);
        assertEq(address(vault.stake()), _stake);
        assertEq(vault.approvalDelay(), stratUpdateDelay);
        assertEq(vault.name(), rivTokenName);
        assertEq(vault.symbol(), rivTokenSymbol);
        assertTrue(Address.isContract(address(vault.strategy())));

        assertEq(vault.strategy().poolId(), _poolId);
        assertEq(address(vault.strategy().reward()), _cake);
        assertEq(address(vault.strategy().lpToken0()), _wom);
        assertEq(address(vault.strategy().lpToken1()), _busd);
        assertEq(address(vault.strategy().chef()), _chef);
        assertEq(vault.strategy().rewardToLp0Route(0), _rewardToLp0Route[0]);
        assertEq(vault.strategy().rewardToLp0Route(1), _rewardToLp0Route[1]);
        assertEq(vault.strategy().rewardToLp0Route(2), _rewardToLp0Route[2]);
        assertEq(vault.strategy().rewardToLp1Route(0), _rewardToLp1Route[0]);
        assertEq(vault.strategy().rewardToLp1Route(1), _rewardToLp1Route[1]);

        vm.prank(_other);
        vm.expectEmit(true, true, true, false);
        emit VaultCreated(_other, _stake, _poolId, address(0));
        address otherVaultAddress = factory.createVault(createVaultParams);

        // assertEq(factory.getVault(_other, _stake, _poolId), otherVaultAddress);
        assertEq(factory.allVaults(1), otherVaultAddress);
        
        assertTrue(Address.isContract(otherVaultAddress));

        RiveraAutoCompoundingVaultV1 otherVault = RiveraAutoCompoundingVaultV1(otherVaultAddress);
        assertEq(address(otherVault.stake()), _stake);
        assertEq(otherVault.approvalDelay(), stratUpdateDelay);
        assertEq(otherVault.name(), rivTokenName);
        assertEq(otherVault.symbol(), rivTokenSymbol);
        assertTrue(Address.isContract(address(otherVault.strategy())));

        assertEq(otherVault.strategy().poolId(), _poolId);
        assertEq(address(otherVault.strategy().reward()), _cake);
        assertEq(address(otherVault.strategy().lpToken0()), _wom);
        assertEq(address(otherVault.strategy().lpToken1()), _busd);
        assertEq(address(otherVault.strategy().chef()), _chef);
        assertEq(vault.strategy().rewardToLp0Route(0), _rewardToLp0Route[0]);
        assertEq(vault.strategy().rewardToLp0Route(1), _rewardToLp0Route[1]);
        assertEq(vault.strategy().rewardToLp0Route(2), _rewardToLp0Route[2]);
        assertEq(vault.strategy().rewardToLp1Route(0), _rewardToLp1Route[0]);
        assertEq(vault.strategy().rewardToLp1Route(1), _rewardToLp1Route[1]);

        assertTrue(vaultAddress != otherVaultAddress);

    }

    function test_UserShouldBeAbleToCreateAnotherVault() public {
        vm.prank(_user);
        CreateVaultParams memory createVaultParams = CreateVaultParams(_poolId, stratUpdateDelay, _rewardToLp0Route, _rewardToLp1Route, rivTokenName, rivTokenSymbol, pendingRewardsFunctionName);
        vm.expectEmit(true, true, true, false);
        emit VaultCreated(_user, _stake, _poolId, address(0));
        address vaultAddress = factory.createVault(createVaultParams);

        // assertEq(factory.getVault(_user, _stake, _poolId), vaultAddress);
        assertEq(factory.allVaults(0), vaultAddress);
        
        assertTrue(Address.isContract(vaultAddress));

        RiveraAutoCompoundingVaultV1 vault = RiveraAutoCompoundingVaultV1(vaultAddress);
        assertEq(address(vault.stake()), _stake);
        assertEq(vault.approvalDelay(), stratUpdateDelay);
        assertEq(vault.name(), rivTokenName);
        assertEq(vault.symbol(), rivTokenSymbol);
        assertTrue(Address.isContract(address(vault.strategy())));

        assertEq(vault.strategy().poolId(), _poolId);
        assertEq(address(vault.strategy().reward()), _cake);
        assertEq(address(vault.strategy().lpToken0()), _wom);
        assertEq(address(vault.strategy().lpToken1()), _busd);
        assertEq(address(vault.strategy().chef()), _chef);
        assertEq(vault.strategy().rewardToLp0Route(0), _rewardToLp0Route[0]);
        assertEq(vault.strategy().rewardToLp0Route(1), _rewardToLp0Route[1]);
        assertEq(vault.strategy().rewardToLp0Route(2), _rewardToLp0Route[2]);
        assertEq(vault.strategy().rewardToLp1Route(0), _rewardToLp1Route[0]);
        assertEq(vault.strategy().rewardToLp1Route(1), _rewardToLp1Route[1]);

        vm.prank(_other);
        vm.expectEmit(true, true, true, false);
        emit VaultCreated(_other, _stake, _poolId, address(0));
        address otherVaultAddress = factory.createVault(createVaultParams);

        // assertEq(factory.getVault(_other, _stake, _poolId), otherVaultAddress);
        assertEq(factory.allVaults(1), otherVaultAddress);
        
        assertTrue(Address.isContract(otherVaultAddress));

        RiveraAutoCompoundingVaultV1 otherVault = RiveraAutoCompoundingVaultV1(otherVaultAddress);
        assertEq(address(otherVault.stake()), _stake);
        assertEq(otherVault.approvalDelay(), stratUpdateDelay);
        assertEq(otherVault.name(), rivTokenName);
        assertEq(otherVault.symbol(), rivTokenSymbol);
        assertTrue(Address.isContract(address(otherVault.strategy())));

        assertEq(otherVault.strategy().poolId(), _poolId);
        assertEq(address(otherVault.strategy().reward()), _cake);
        assertEq(address(otherVault.strategy().lpToken0()), _wom);
        assertEq(address(otherVault.strategy().lpToken1()), _busd);
        assertEq(address(otherVault.strategy().chef()), _chef);
        assertEq(vault.strategy().rewardToLp0Route(0), _rewardToLp0Route[0]);
        assertEq(vault.strategy().rewardToLp0Route(1), _rewardToLp0Route[1]);
        assertEq(vault.strategy().rewardToLp0Route(2), _rewardToLp0Route[2]);
        assertEq(vault.strategy().rewardToLp1Route(0), _rewardToLp1Route[0]);
        assertEq(vault.strategy().rewardToLp1Route(1), _rewardToLp1Route[1]);

        assertTrue(vaultAddress != otherVaultAddress);

        vm.prank(_user);
        createVaultParams = CreateVaultParams(_poolId2, stratUpdateDelay, _rewardToLp0Route2, _rewardToLp1Route2, rivTokenName2, rivTokenSymbol2, pendingRewardsFunctionName);
        vm.expectEmit(true, true, true, false);
        emit VaultCreated(_user, _stake2, _poolId2, address(0));
        address vault2Address = factory.createVault(createVaultParams);

        // assertEq(factory.getVault(_user, _stake2, _poolId2), vault2Address);
        assertEq(factory.allVaults(2), vault2Address);
        
        assertTrue(Address.isContract(vault2Address));

        RiveraAutoCompoundingVaultV1 vault2 = RiveraAutoCompoundingVaultV1(vault2Address);
        assertEq(address(vault2.stake()), _stake2);
        assertEq(vault2.approvalDelay(), stratUpdateDelay);
        assertEq(vault2.name(), rivTokenName2);
        assertEq(vault2.symbol(), rivTokenSymbol2);
        assertTrue(Address.isContract(address(vault2.strategy())));

        assertEq(vault2.strategy().poolId(), _poolId2);
        assertEq(address(vault2.strategy().reward()), _cake);
        assertEq(address(vault2.strategy().lpToken0()), _spin);
        assertEq(address(vault2.strategy().lpToken1()), _wbnb);
        assertEq(address(vault2.strategy().chef()), _chef);
        assertEq(vault2.strategy().rewardToLp0Route(0), _rewardToLp0Route2[0]);
        assertEq(vault2.strategy().rewardToLp0Route(1), _rewardToLp0Route2[1]);
        assertEq(vault2.strategy().rewardToLp0Route(2), _rewardToLp0Route2[2]);
        assertEq(vault2.strategy().rewardToLp1Route(0), _rewardToLp1Route2[0]);
        assertEq(vault2.strategy().rewardToLp1Route(1), _rewardToLp1Route2[1]);

    }

}