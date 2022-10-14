pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../src/strategies/cake/CakeLpStakingV1.sol";
import "../../../src/strategies/common/interfaces/IStrategy.sol";
import "../../../src/vaults/RiveraAutoCompoundingVaultV1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

///@dev
///As there is dependency on Cake swap protocol. Replicating the protocol deployment on separately is difficult. Hence we would test on main net fork of BSC.
///The addresses used below must also be mainnet addresses.

contract CakeLpStakingV1Test is Test {
    CakeLpStakingV1 strategy;
    RiveraAutoCompoundingVaultV1 vault;

    //Events
    event StratHarvest(
        address indexed harvester,
        uint256 stakeHarvested,
        uint256 tvl
    );
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);

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
        CommonAddresses memory _commonAddresses = CommonAddresses(address(vault), _router, _manager);
        strategy = new CakeLpStakingV1(_stake, _poolId, _chef, _commonAddresses, _rewardToNativeRoute, _rewardToLp0Route, _rewardToLp1Route);
        vault.init(IStrategy(address(strategy)));
        vm.stopPrank();

        ///@dev Transfering LP tokens from a whale to my accounts
        vm.startPrank(_whale);
        IERC20(_stake).transfer(_user, 1e22);
        IERC20(_stake).transfer(_other, 1e22);
        vm.stopPrank();

    }

    ///@notice tests for deposit function

    function test_DepositWhenNotPausedAndCalledByVault() public {
        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.expectEmit(false, false, false, true);
        emit Deposit(1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 stratStakeBalanceAfter = strategy.balanceOfPool();

        assertEq(stratStakeBalanceAfter, 1e18);
    }

    function test_DepositWhenPaused() public {
        vm.prank(_manager);
        strategy.pause();
        vm.prank(address(vault));
        vm.expectRevert("Pausable: paused");
        strategy.deposit();
    }

    function test_DepositWhenNotVault() public {
        vm.expectRevert("!vault");
        strategy.deposit();
    }

    ///@notice tests for withdraw function

    function test_WithdrawWhenCalledByVault() public {
        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 vaultStakeBalanceBefore = IERC20(_stake).balanceOf(address(vault));
        assertEq(vaultStakeBalanceBefore, 0);
        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
        assertEq(stratPoolBalanceBefore, 1e18);

        vm.prank(address(vault));
        vm.expectEmit(false, false, false, true);
        emit Withdraw(0);  //Event emitted it Withdraw(tvl after withdraw)
        strategy.withdraw(1e18);

        uint256 vaultStakeBalanceAfter = IERC20(_stake).balanceOf(address(vault));
        assertEq(vaultStakeBalanceAfter, 1e18);
        uint256 stratPoolBalanceAfter = strategy.balanceOfPool();
        assertEq(stratPoolBalanceAfter, 0);

    }

    function test_WithdrawWhenNotCalledByVault() public {
        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 vaultStakeBalanceBefore = IERC20(_stake).balanceOf(address(vault));
        assertEq(vaultStakeBalanceBefore, 0);
        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
        assertEq(stratPoolBalanceBefore, 1e18);

        vm.expectRevert("!vault");
        strategy.withdraw(1e18);

    }

    ///@notice tests for harvest functions

    function test_HarvestWhenNotPaused() public {
        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
        assertEq(stratPoolBalanceBefore, 1e18);

        vm.roll(block.number + 100);

        vm.expectEmit(true, false, false, false);
        emit StratHarvest(address(this), 0, 0); //We don't try to match the second and third parameter of the event. They're result of Pancake swap contracts, we trust the protocol to be correct.
        strategy.harvest();
        
        uint256 stratPoolBalanceAfter = strategy.balanceOfPool();
        assertGt(stratPoolBalanceAfter, stratPoolBalanceBefore);
    }

    function test_HarvestWhenPaused() public {
        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
        assertEq(stratPoolBalanceBefore, 1e18);

        vm.roll(block.number + 100);

        vm.prank(_manager);
        strategy.pause();
        vm.expectRevert("Pausable: paused");
        strategy.harvest();
    }

    ///@notice tests for manager harvest functions

    function test_HarvestWhenCalledByManager() public {
        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
        assertEq(stratPoolBalanceBefore, 1e18);

        vm.roll(block.number + 100);

        vm.prank(_manager);
        vm.expectEmit(true, false, false, false);
        emit StratHarvest(_manager, 0, 0); //We don't try to match the second and third parameter of the event. They're result of Pancake swap contracts, we trust the protocol to be correct.
        strategy.managerHarvest();
        
        uint256 stratPoolBalanceAfter = strategy.balanceOfPool();
        assertGt(stratPoolBalanceAfter, stratPoolBalanceBefore);
    }

    function test_HarvestWhenNotCalledByManager() public {
        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
        assertEq(stratPoolBalanceBefore, 1e18);

        vm.roll(block.number + 100);

        vm.prank(_manager);
        strategy.pause();
        vm.expectRevert("!manager");
        strategy.managerHarvest();
    }

    function test_BalanceOfStake() public {
        uint256 stratStakeBalanceBefore = strategy.balanceOfStake();
        assertEq(stratStakeBalanceBefore, 0);

        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);

        uint256 stratStakeBalanceAfter = strategy.balanceOfStake();
        assertEq(stratStakeBalanceAfter, 1e18);
    }

    function test_BalanceOfPool() public {
        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
        assertEq(stratPoolBalanceBefore, 0);

        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 stratPoolBalanceAfter = strategy.balanceOfPool();
        assertEq(stratPoolBalanceAfter, 1e18);
    }

    function test_BalanceOfStrategy() public {
        uint256 stratBalanceBefore = strategy.balanceOf();
        assertEq(stratBalanceBefore, 0);

        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);

        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 stratBalanceAfter = strategy.balanceOf();
        assertEq(stratBalanceAfter, 2e18);
    }

    function test_SetPendingRewardsFunctionNameCalledByManager() public {
        assertEq(strategy.pendingRewardsFunctionName(), "");

        vm.prank(_manager);
        strategy.setPendingRewardsFunctionName("pendingCake");

        assertEq(strategy.pendingRewardsFunctionName(), "pendingCake");
    }

    function test_SetPendingRewardsFunctionNameNotCalledByManager() public {
        assertEq(strategy.pendingRewardsFunctionName(), "");

        vm.expectRevert("!manager");
        strategy.setPendingRewardsFunctionName("pendingCake");

    }

    function test_RewardsAvailable() public {
        assertEq(strategy.pendingRewardsFunctionName(), "");

        vm.prank(_manager);
        strategy.setPendingRewardsFunctionName("pendingCake");

        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
        assertEq(stratPoolBalanceBefore, 1e18);

        vm.roll(block.number + 100);

        assertGt(strategy.rewardsAvailable(), 0);

    }

    function testFail_RewardsAvailableBeforeSettingFunctionName() public {
        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
        assertEq(stratPoolBalanceBefore, 1e18);

        vm.roll(block.number + 100);

        assertGt(strategy.rewardsAvailable(), 0);
    }

    function test_RetireStratWhenCalledByVault() public {

        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);

        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
        assertEq(stratPoolBalanceBefore, 1e18);

        uint256 stratStakeBalanceBefore = strategy.balanceOfStake();
        assertEq(stratStakeBalanceBefore, 1e18);

        uint256 vaultStakeBalanceBefore = IERC20(_stake).balanceOf(address(vault));
        assertEq(vaultStakeBalanceBefore, 0);

        vm.prank(address(vault));
        strategy.retireStrat();

        uint256 stratPoolBalanceAfterr = strategy.balanceOfPool();
        assertEq(stratPoolBalanceAfterr, 0);

        uint256 stratStakeBalanceAfter = strategy.balanceOfStake();
        assertEq(stratStakeBalanceAfter, 0);

        uint256 vaultStakeBalanceAfter = IERC20(_stake).balanceOf(address(vault));
        assertEq(vaultStakeBalanceAfter, 2e18);

    }

    function test_RetireStratWhenNotCalledByVault() public {

        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);

        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
        assertEq(stratPoolBalanceBefore, 1e18);

        uint256 stratStakeBalanceBefore = strategy.balanceOfStake();
        assertEq(stratStakeBalanceBefore, 1e18);

        uint256 vaultStakeBalanceBefore = IERC20(_stake).balanceOf(address(vault));
        assertEq(vaultStakeBalanceBefore, 0);

        vm.expectRevert("!vault");
        strategy.retireStrat();

    }

    function test_PanicWhenCalledByManager() public {
        vm.prank(_manager);
        strategy.panic();

        assertEq(strategy.paused(), true);

        assertEq(IERC20(_stake).allowance(address(strategy), _chef), 0);
        assertEq(IERC20(_cake).allowance(address(strategy), _router), 0);
        assertEq(IERC20(_wom).allowance(address(strategy), _router), 0);
        assertEq(IERC20(_busd).allowance(address(strategy), _router), 0);
    }

    function test_PanicWhenNotCalledByManager() public {
        vm.expectRevert("!manager");
        strategy.panic();
    }

    function test_UnpauseWhenCalledByManager() public {
        vm.prank(_manager);
        strategy.panic();

        assertEq(strategy.paused(), true);

        assertEq(IERC20(_stake).allowance(address(strategy), _chef), 0);
        assertEq(IERC20(_cake).allowance(address(strategy), _router), 0);
        assertEq(IERC20(_wom).allowance(address(strategy), _router), 0);
        assertEq(IERC20(_busd).allowance(address(strategy), _router), 0);

        vm.prank(_manager);
        strategy.unpause();

        assertEq(strategy.paused(), false);

        assertEq(IERC20(_stake).allowance(address(strategy), _chef), type(uint256).max);
        assertEq(IERC20(_cake).allowance(address(strategy), _router), type(uint256).max);
        assertEq(IERC20(_wom).allowance(address(strategy), _router), type(uint256).max);
        assertEq(IERC20(_busd).allowance(address(strategy), _router), type(uint256).max);
    }

    function test_UnpauseWhenNotCalledByManager() public {
        vm.expectRevert("!manager");
        strategy.unpause();
    }
}