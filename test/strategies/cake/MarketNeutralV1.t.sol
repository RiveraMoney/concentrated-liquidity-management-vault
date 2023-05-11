pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../src/strategies/cake/MarketNeutralV1.sol";
import "../../../src/strategies/common/interfaces/IStrategy.sol";
import "../../../src/vaults/RiveraAutoCompoundingVaultV1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

///@dev
///As there is dependency on Cake swap protocol. Replicating the protocol deployment on separately is difficult. Hence we would test on main net fork of BSC.
///The addresses used below must also be mainnet addresses.

enum UpdatePositionType {
    INCREASE,
    DECREASE
}

enum OrderType {
    MARKET,
    LIMIT
}

enum Side {
    LONG,
    SHORT
}

interface ILevelOrderManager {
    function placeOrder(
        UpdatePositionType _updateType,
        Side _side,
        address _indexToken,
        address _collateralToken,
        OrderType _orderType,
        bytes calldata data
    ) external payable;

    function nextOrderId() external view returns (uint256);
}

interface ILevelOracle {
    function postPrices(
        address[] calldata tokens,
        uint256[] calldata prices
    ) external;
}

interface ITradeExecutor {
    function executeOrders(
        uint256[] calldata perpOrders,
        uint256[] calldata swapOrders
    ) external;
}

struct Position {
    uint256 size;
    uint256 collateralValue;
    uint256 reserveAmount;
    uint256 entryPrice;
    uint256 borrowIndex;
}

interface ILevelPool {
    function positions(bytes32) external view returns (Position memory);
}

contract MarketNeutralV1Test is Test {
    MarketNeutralV1 strategy;
    RiveraAutoCompoundingVaultV1 vault;

    //Events
    event StratHarvest(
        address indexed harvester,
        uint256 stakeHarvested,
        uint256 tvl
    );
    event Deposit(uint256 tvl, uint256 amount);
    event Withdraw(uint256 tvl, uint256 amount);

    ///@dev Required addresses from mainnet
    ///@notice Currrent addresses are for the BUSD-WOM pool
    //TODO: move these address configurations to an external file and keep it editable and configurable
    address _stake = 0x36696169C63e42cd08ce11f5deeBbCeBae652050; //Mainnet address of the LP Pool you're deploying funds to. It is also the ERC20 token contract of the LP token.
    uint256 _poolId = 116; //In Pancake swap every Liquidity Pool has a pool id. This is the pool id of the LP pool we're testing.
    address _chef = 0x556B9306565093C855AEA9AE92A594704c2Cd59e; //Address of the pancake master chef v3 contract on BSC mainnet
    address _router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4; //Address of Pancake Swap router v3
    // address _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //v2
    address _cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82; //Adress of the CAKE ERC20 token on mainnet
    address _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //Address of wrapped version of BNB which is the native token of BSC
    address _busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address _usdt = 0x55d398326f99059fF775485246999027B3197955;
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
    address _manager = 0xbA79a22A4b8018caFDC24201ab934c9AdF6903d7;
    address _other = 0xF18Bb60E7Bd9BD65B61C57b9Dd89cfEb774274a1;
    address _whale = 0x14bA0D857C496C03A8c8D5Fcc6c92d30Df804775;
    address _whaleUsdt = 0xc686D5a4A1017BC1B751F25eF882A16AB1A81B63;
    address _factory = 0x4B16c5dE96EB2117bBE5fd171E4d203624B014aa;
    address _NonfungiblePositionManager =
        0x46A15B0b27311cedF172AB29E4f4766fbE7F4364;
    address _OrderManager = 0xf584A17dF21Afd9de84F47842ECEAF6042b1Bb5b;
    address _indexTokenChainlink = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address _LevelPoolLens = 0xbB89B4910DaB84FF62EeD0A3E0892C5f5876C49a;
    uint256 _leverage = 3;

    address PRICE_REPORTER = 0xe423BB0a8b925EABF625A8f36B468ab009a854e7;

    ILevelOracle LEVEL_ORACLE =
        ILevelOracle(0x04Db83667F5d59FF61fA6BbBD894824B233b3693);

    ILevelPool LEVEL_POOL =
        ILevelPool(0xA5aBFB56a78D2BD4689b25B8A77fd49Bb0675874);

    ITradeExecutor TRADE_EXECUTOR =
        ITradeExecutor(0x6cd4c40016F10E1609f16fB4a84CAe4700a4DaD6);

    function setUp() public {
        ///@dev creating the routes
        _rewardToNativeRoute[0] = _usdt;
        _rewardToNativeRoute[1] = _wbnb;

        _rewardToLp0Route[0] = _cake;
        _rewardToLp0Route[1] = _usdt;

        _rewardToLp1Route[0] = _cake;
        _rewardToLp1Route[1] = _wbnb;

        ///@dev all deployments will be made by the user
        vm.startPrank(_user);

        ///@dev Initializing the vault with invalid strategy
        vault = new RiveraAutoCompoundingVaultV1(
            rivTokenName,
            rivTokenSymbol,
            stratUpdateDelay
        );

        ///@dev Initializing the strategy
        CommonAddresses memory _commonAddresses = CommonAddresses(
            address(vault),
            _router,
            _NonfungiblePositionManager
        ); //["vault","0x10ED43C718714eb63d5aA57B78B54704E256024E"]
        CakePoolParams memory cakePoolParams = CakePoolParams(
            _stake,
            _chef,
            _rewardToLp0Route,
            _rewardToLp1Route,
            true,
            -57260,
            -57170
        ); //["0x36696169C63e42cd08ce11f5deeBbCeBae652050","0x556B9306565093C855AEA9AE92A594704c2Cd59e",["0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82","0x55d398326f99059ff775485246999027b3197955"],["0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82","0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"],true,-57260,-57170]
        ShortParams memory shortParams = ShortParams(
            _OrderManager,
            _indexTokenChainlink,
            _LevelPoolLens,
            3
        );
        strategy = new MarketNeutralV1(
            cakePoolParams,
            _commonAddresses,
            shortParams
        );
        vm.stopPrank();

        vm.prank(_factory);
        vault.init(IStrategy(address(strategy)));
        vm.stopPrank();
        ///@dev Transfering LP tokens from a whale to my accounts
        vm.startPrank(_whaleUsdt);
        IERC20(_usdt).transfer(_user, 42e22);
        IERC20(_usdt).transfer(_other, 42e22);
        vm.deal(address(vault), 1 ether);
        vm.stopPrank();
    }

    //@notice tests for deposit function

    function test_DepositWhenNotPausedAndCalledByVault() public {
        vm.prank(_user);
        IERC20(_usdt).transfer(address(strategy), 42e18);
        // // vm.expectEmit(false, false, false, true);
        // // emit Deposit(1e18, 1e18);
        vm.prank(address(vault));
        strategy.splitAndDeposit{value: 3500000000000000}();

        uint256 orderId = ILevelOrderManager(_OrderManager).nextOrderId() - 1;
        uint256 indexTokenPrice = strategy._getChainlinkPrice() / 1e4;
        console.log("index price", indexTokenPrice);
        console.log("orderId", orderId);
        vm.stopPrank();

        vm.roll(block.number + 1);
        {
            address[] memory tokens = new address[](1);
            tokens[0] = _wbnb;
            uint256[] memory prices = new uint[](1);
            prices[0] = indexTokenPrice;
            vm.startPrank(PRICE_REPORTER);
            LEVEL_ORACLE.postPrices(tokens, prices);
        }

        // EXECUTE ORDER, can be called by LevelKeeper, or anyone interest
        {
            uint256[] memory orders = new uint[](1);
            orders[0] = orderId;
            uint256[] memory swapOrders = new uint[](0);
            TRADE_EXECUTOR.executeOrders(orders, swapOrders);
        }
        // check if position is opened
        bytes32 positionId = keccak256(
            abi.encode(strategy, _wbnb, _usdt, Side.SHORT)
        );
        vm.roll(block.number + 1);
        Position memory position = LEVEL_POOL.positions(positionId);
        console.log("position collateral value", position.collateralValue);

        //balanceofStablecoin of vault
        uint256 balanceOfStablecoin_Strategy = IERC20(_usdt).balanceOf(
            address(strategy)
        );
        console.log(
            "balanceOfStablecoin_stratedy before",
            balanceOfStablecoin_Strategy
        );
        vm.stopPrank();

        /*//         lets rebalance         //*/
        console.log("==============================================");

        //lets withdraw
        vm.roll(block.number + 10);
        vm.prank(address(vault));
        strategy.withdrawShortPosition{value: 3500000000000000}(
            position.collateralValue,
            // 4982000005491200000000000000000,
            position.size,
            MarketNeutralV1.UpdatePositionType.DECREASE
        );

        orderId = ILevelOrderManager(_OrderManager).nextOrderId() - 1;
        indexTokenPrice = strategy._getChainlinkPrice() / 1e4;
        console.log("index price after rebalance deposit", indexTokenPrice);
        console.log("orderId of decrease", orderId);
        vm.stopPrank();
        vm.roll(block.number + 1);

        {
            address[] memory tokens = new address[](1);
            tokens[0] = _wbnb;
            uint256[] memory prices = new uint[](1);
            prices[0] = indexTokenPrice;
            vm.startPrank(PRICE_REPORTER);
            LEVEL_ORACLE.postPrices(tokens, prices);
        }

        // EXECUTE ORDER, can be called by LevelKeeper, or anyone interest
        {
            uint256[] memory orders = new uint[](1);
            orders[0] = orderId;
            uint256[] memory swapOrders = new uint[](0);
            TRADE_EXECUTOR.executeOrders(orders, swapOrders);
        }

        // check if position is opened
        positionId = keccak256(abi.encode(strategy, _wbnb, _usdt, Side.SHORT));

        vm.roll(block.number + 1);
        position = LEVEL_POOL.positions(positionId);
        console.log(
            "position collateral value after rebalance",
            position.collateralValue
        );
        console.log("position size value after rebalance", position.size);

        //balanceofStablecoin of strategy
        balanceOfStablecoin_Strategy = IERC20(_usdt).balanceOf(
            address(strategy)
        );
        console.log(
            "balanceOfStablecoin_stratedy after",
            balanceOfStablecoin_Strategy
        );

        //balanceofStablecoin of vault
        uint256 balanceOfStablecoin_Vault = IERC20(_usdt).balanceOf(
            address(vault)
        );
        console.log(
            "balanceOfStablecoin_vault after",
            balanceOfStablecoin_Vault
        );

        // assertEq(stratStakeBalanceAfter, 1e18);
    }
}
