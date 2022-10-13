pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/strategies/cake/CakeLpStakingV1.sol";
import "../../src/strategies/common/interfaces/IStrategy.sol";
import "../../src/vaults/RiveraAutoCompoundingVaultV1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

///@dev
///As there is dependency on Cake swap protocol. Replicating the protocol deployment on separately is difficult. Hence we would test on main net fork of BSC.
///The addresses used below must also be mainnet addresses.

contract RiveraAutoCompoundingVaultV1Test is Test {
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

    event NewStratCandidate(address implementation);
    event UpgradeStrat(address implementation);

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

    CommonAddresses _commonAddresses;

    function setUp() public {
        ///@dev creating the routes
        _rewardToNativeRoute.push(_cake);
        _rewardToNativeRoute.push(_wbnb);

        _rewardToLp0Route.push(_cake);
        _rewardToLp0Route.push(_busd);
        _rewardToLp0Route.push(_wom);

        _rewardToLp1Route.push(_cake);
        _rewardToLp1Route.push(_busd);

        ///@dev all deployments will be made by the user
        vm.startPrank(_user);

        ///@dev Initializing the vault with invalid strategy
        vault = new RiveraAutoCompoundingVaultV1(IStrategy(0x14bA0D857C496C03A8c8D5Fcc6c92d30Df804775), rivTokenName, rivTokenSymbol, stratUpdateDelay);

        ///@dev Initializing the strategy
        _commonAddresses = CommonAddresses(address(vault), _router, _manager);
        strategy = new CakeLpStakingV1(_stake, _poolId, _chef, _commonAddresses, _rewardToNativeRoute, _rewardToLp0Route, _rewardToLp1Route);

        ///@dev updating the strategy with the deployed one
        vault.proposeStrat(address(strategy));
        vm.warp(block.timestamp + 21600 + 1);
        vault.upgradeStrat();

        ///@dev Transfering LP tokens from a whale to my accounts
        vm.startPrank(_whale);
        IERC20(_stake).transfer(_user, 1e24);
        IERC20(_stake).transfer(_other, 1e24);
        IERC20(_busd).transfer(_user, 1e19);
        vm.stopPrank();

        ///@dev Giving approval to required contracts
        vm.prank(_manager);
        strategy.unpause();
        vm.prank(_user);
        IERC20(_stake).approve(address(vault), type(uint).max);

    }

    function test_Balance() public {
        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);
        vm.prank(address(vault));
        strategy.deposit();

        uint256 totalBalance = vault.balance();
        assertEq(totalBalance, 1e18);

        vm.prank(_user);
        IERC20(_stake).transfer(address(strategy), 1e18);

        totalBalance = vault.balance();
        assertEq(totalBalance, 2e18);

        vm.prank(_user);
        IERC20(_stake).transfer(address(vault), 1e18);

        totalBalance = vault.balance();
        assertEq(totalBalance, 3e18);

    }

    function test_Available() public {

        vm.prank(_user);
        IERC20(_stake).transfer(address(vault), 1e18);

        uint256 balanceAvailableToDeploy = vault.available();
        assertEq(balanceAvailableToDeploy, 1e18);

    }

    function test_DepositWhenDoneByOwnerAndTotalSupplyZero() public {

        uint256 userStakeBalanceBefore = IERC20(_stake).balanceOf(_user);
        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();

        vm.prank(_user);
        vault.deposit(1e18);

        uint256 userStakeBalanceAfter = IERC20(_stake).balanceOf(_user);
        assertEq(userStakeBalanceBefore - userStakeBalanceAfter, 1e18);

        uint256 stratPoolBalanceAfter = strategy.balanceOfPool();
        assertEq(stratPoolBalanceAfter - stratPoolBalanceBefore, 1e18);

        assertEq(vault.balanceOf(_user), 1e18);
    }

    function test_DepositWhenDoneByOwnerAndTotalSupplyNotZero() public {

        vm.prank(_user);
        vault.deposit(1e18);

        vm.warp(30 * 21600);
        strategy.harvest();

        uint256 userStakeBalanceBefore = IERC20(_stake).balanceOf(_user);
        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();

        vm.prank(_user);
        vault.deposit(1e18);

        uint256 userStakeBalanceAfter = IERC20(_stake).balanceOf(_user);
        assertEq(userStakeBalanceBefore - userStakeBalanceAfter, 1e18);

        uint256 stratPoolBalanceAfter = strategy.balanceOfPool();
        assertEq(stratPoolBalanceAfter - stratPoolBalanceBefore, 1e18);

        require(vault.balanceOf(_user) < 2e18);
    }

    function test_DepositWhenNotDoneByOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vault.deposit(1e18);
    }

    function test_DepositAll() public {
        uint256 userStakeBalanceBefore = IERC20(_stake).balanceOf(_user);
        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();

        vm.prank(_user);
        vault.depositAll();

        uint256 userStakeBalanceAfter = IERC20(_stake).balanceOf(_user);
        assertEq(userStakeBalanceBefore - userStakeBalanceAfter, userStakeBalanceBefore);

        uint256 stratPoolBalanceAfter = strategy.balanceOfPool();
        assertEq(stratPoolBalanceAfter - stratPoolBalanceBefore, userStakeBalanceBefore);

        assertEq(vault.balanceOf(_user), userStakeBalanceBefore);
    }

    function test_GetPricePerFullShare() public {
        vm.prank(_user);
        vault.deposit(1e18);

        uint256 pricePerFullShareBefore = vault.getPricePerFullShare();

        vm.warp(30 * 21600);
        strategy.harvest();

        uint256 pricePerFullShareAfter = vault.getPricePerFullShare();

        assertEq(pricePerFullShareBefore, 1e18);
        require(pricePerFullShareAfter > pricePerFullShareBefore);

    }

    function test_EarnWhenCalledByOwner() public {
        uint256 userStakeBalanceBefore = IERC20(_stake).balanceOf(_user);
        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();

        vm.startPrank(_user);
        IERC20(_stake).transfer(address(vault), 1e18);
        vault.earn();
        vm.stopPrank();

        uint256 userStakeBalanceAfter = IERC20(_stake).balanceOf(_user);
        assertEq(userStakeBalanceBefore - userStakeBalanceAfter, 1e18);

        uint256 stratPoolBalanceAfter = strategy.balanceOfPool();
        assertEq(stratPoolBalanceAfter - stratPoolBalanceBefore, 1e18);

    }

    function test_EarnWhenNotCalledByOwner() public {
        uint256 userStakeBalanceBefore = IERC20(_stake).balanceOf(_user);
        uint256 stratPoolBalanceBefore = strategy.balanceOfPool();

        vm.startPrank(_user);
        IERC20(_stake).transfer(address(vault), 1e18);
        vm.stopPrank();
        vm.expectRevert("Ownable: caller is not the owner");
        vault.earn();

        uint256 userStakeBalanceAfter = IERC20(_stake).balanceOf(_user);
        assertEq(userStakeBalanceBefore - userStakeBalanceAfter, 1e18);

        uint256 stratPoolBalanceAfter = strategy.balanceOfPool();
        assertEq(stratPoolBalanceAfter - stratPoolBalanceBefore, 1e18);

    }

    function test_WithdrawWhenCalledByOwner() public {

        vm.prank(_user);
        vault.deposit(2e18);

        vm.warp(30 * 21600);
        strategy.harvest();

        uint256 userShareBefore = vault.balanceOf(_user);
        assertEq(userShareBefore, 2e18);
        uint256 userStakeBalanceBefore = IERC20(_stake).balanceOf(_user);
        uint256 vaultBalanceBefore = vault.balance();

        vm.prank(_user);
        vault.withdraw(1e18);

        uint256 userShareAfter = vault.balanceOf(_user);
        assertEq(userShareAfter, 1e18);
        uint256 userStakeBalanceAfter = IERC20(_stake).balanceOf(_user);
        assertGt(userStakeBalanceAfter - userStakeBalanceBefore, 1e18);
        uint256 vaultBalanceAfter = vault.balance();
        assertGt(vaultBalanceBefore - vaultBalanceAfter, 1e18);

    }

    function test_WithdrawWhenNotCalledByOwner() public {
        vm.prank(_user);
        vault.deposit(2e18);

        vm.warp(30 * 21600);
        strategy.harvest();

        vm.expectRevert("Ownable: caller is not the owner");
        vault.withdraw(1e18);
    }

    function test_WithdrawAll() public {
        vm.prank(_user);
        vault.deposit(2e18);

        vm.warp(30 * 21600);
        strategy.harvest();

        uint256 userShareBefore = vault.balanceOf(_user);
        assertEq(userShareBefore, 2e18);
        uint256 userStakeBalanceBefore = IERC20(_stake).balanceOf(_user);
        uint256 vaultBalanceBefore = vault.balance();

        vm.prank(_user);
        vault.withdrawAll();

        uint256 userShareAfter = vault.balanceOf(_user);
        assertEq(userShareAfter, 0);
        uint256 userStakeBalanceAfter = IERC20(_stake).balanceOf(_user);
        assertGt(userStakeBalanceAfter - userStakeBalanceBefore, 2e18);
        uint256 vaultBalanceAfter = vault.balance();
        assertGt(vaultBalanceBefore - vaultBalanceAfter, 2e18);
    }

    function test_ProposeStratWithCorrectVault() public {

        CakeLpStakingV1 newStrat = new CakeLpStakingV1(_stake, _poolId, _chef, _commonAddresses, _rewardToNativeRoute, _rewardToLp0Route, _rewardToLp1Route);

        StratCandidate memory currentStratCandidate = vault.getStratProposal();
        assertEq(currentStratCandidate.implementation, address(0));
        assertEq(currentStratCandidate.proposedTime, 0);

        vm.prank(_user);
        vm.expectEmit(false, false, false, true);
        emit NewStratCandidate(address(newStrat));
        uint256 proposedTime = block.timestamp;
        vault.proposeStrat(address(newStrat));

        StratCandidate memory newStratCandidate = vault.getStratProposal();
        assertEq(newStratCandidate.implementation, address(newStrat));
        assertEq(newStratCandidate.proposedTime, proposedTime);
    }

    function test_ProposeStratWithInCorrectVault() public {

        _commonAddresses = CommonAddresses(address(0), _router, _manager);
        CakeLpStakingV1 newStrat = new CakeLpStakingV1(_stake, _poolId, _chef, _commonAddresses, _rewardToNativeRoute, _rewardToLp0Route, _rewardToLp1Route);

        vm.expectRevert("Proposal not valid for this Vault");
        vault.proposeStrat(address(newStrat));

    }

    function test_ProposeStratWithCorrectVaultButNotOwner() public {

        CakeLpStakingV1 newStrat = new CakeLpStakingV1(_stake, _poolId, _chef, _commonAddresses, _rewardToNativeRoute, _rewardToLp0Route, _rewardToLp1Route);

        vm.expectRevert("Ownable: caller is not the owner");
        vault.proposeStrat(address(newStrat));
    }

    function test_UpgradeStratWithCorrectOwnerAndAfterDelay() public {
        CakeLpStakingV1 newStrat = new CakeLpStakingV1(_stake, _poolId, _chef, _commonAddresses, _rewardToNativeRoute, _rewardToLp0Route, _rewardToLp1Route);

        StratCandidate memory currentStratCandidate = vault.getStratProposal();
        assertEq(currentStratCandidate.implementation, address(0));
        assertEq(currentStratCandidate.proposedTime, 0);

        vm.prank(_user);
        vm.expectEmit(false, false, false, true);
        emit NewStratCandidate(address(newStrat));
        uint256 proposedTime = block.timestamp;
        vault.proposeStrat(address(newStrat));

        StratCandidate memory newStratCandidate = vault.getStratProposal();
        assertEq(newStratCandidate.implementation, address(newStrat));
        assertEq(newStratCandidate.proposedTime, proposedTime);

        assertEq(address(vault.strategy()), address(strategy));

        vm.warp(21600 + 1);

        vm.prank(_user);
        vm.expectEmit(false, false, false, true);
        emit UpgradeStrat(newStratCandidate.implementation);
        vault.upgradeStrat();

        assertEq(address(vault.strategy()), address(newStrat));
    }

    function test_UpgradeStratWithCorrectOwnerAndBeforeDelay() public {
        CakeLpStakingV1 newStrat = new CakeLpStakingV1(_stake, _poolId, _chef, _commonAddresses, _rewardToNativeRoute, _rewardToLp0Route, _rewardToLp1Route);

        StratCandidate memory currentStratCandidate = vault.getStratProposal();
        assertEq(currentStratCandidate.implementation, address(0));
        assertEq(currentStratCandidate.proposedTime, 0);

        vm.prank(_user);
        vm.expectEmit(false, false, false, true);
        emit NewStratCandidate(address(newStrat));
        uint256 proposedTime = block.timestamp;
        vault.proposeStrat(address(newStrat));

        StratCandidate memory newStratCandidate = vault.getStratProposal();
        assertEq(newStratCandidate.implementation, address(newStrat));
        assertEq(newStratCandidate.proposedTime, proposedTime);

        assertEq(address(vault.strategy()), address(strategy));

        vm.prank(_user);
        vm.expectRevert("Delay has not passed");
        vault.upgradeStrat();

    }

    function test_UpgradeStratWithInCorrectOwnerAndAfterDelay() public {
        CakeLpStakingV1 newStrat = new CakeLpStakingV1(_stake, _poolId, _chef, _commonAddresses, _rewardToNativeRoute, _rewardToLp0Route, _rewardToLp1Route);

        StratCandidate memory currentStratCandidate = vault.getStratProposal();
        assertEq(currentStratCandidate.implementation, address(0));
        assertEq(currentStratCandidate.proposedTime, 0);

        vm.prank(_user);
        vm.expectEmit(false, false, false, true);
        emit NewStratCandidate(address(newStrat));
        uint256 proposedTime = block.timestamp;
        vault.proposeStrat(address(newStrat));

        StratCandidate memory newStratCandidate = vault.getStratProposal();
        assertEq(newStratCandidate.implementation, address(newStrat));
        assertEq(newStratCandidate.proposedTime, proposedTime);

        assertEq(address(vault.strategy()), address(strategy));

        vm.warp(21600 + 1);

        vm.expectRevert("Ownable: caller is not the owner");
        vault.upgradeStrat();

    }

    function test_UpgradeStratWithInCorrectImplementationAfterDelay() public {

        vm.prank(_user);
        vm.expectRevert("There is no candidate");
        vault.upgradeStrat();

    }

    function test_InCaseTokenGetsStuck() public {
        vm.prank(_user);
        IERC20(_busd).transfer(address(vault), 5e18);

        assertEq(IERC20(_busd).balanceOf(address(vault)), 5e18);
        uint256 userBalanceBefore = IERC20(_busd).balanceOf(_user);

        vm.prank(_user);
        vault.inCaseTokensGetStuck(_busd);

        assertEq(IERC20(_busd).balanceOf(address(vault)), 0);
        uint256 userBalanceAfter = IERC20(_busd).balanceOf(_user);
        assertEq(userBalanceAfter - userBalanceBefore, 5e18);

    }

    function test_InCaseTokenGetsStuckForStake() public {

        vm.prank(_user);
        vm.expectRevert("!token");
        vault.inCaseTokensGetStuck(_stake);

    }

    function test_InCaseTokenGetsStuckNotOwner() public {
        vm.prank(_user);
        IERC20(_busd).transfer(address(vault), 5e18);

        vm.expectRevert("Ownable: caller is not the owner");
        vault.inCaseTokensGetStuck(_busd);

    }

}