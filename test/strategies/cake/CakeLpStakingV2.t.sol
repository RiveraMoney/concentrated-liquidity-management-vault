pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../src/strategies/cake/CakeLpStakingV2.sol";
import "../../../src/strategies/common/interfaces/IStrategy.sol";
import "../../../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";

import "@rivera/strategies/cake/interfaces/INonfungiblePositionManager.sol";
import "@pancakeswap-v3-core/interfaces/IPancakeV3Pool.sol";
import "@pancakeswap-v3-core/interfaces/IPancakeV3Factory.sol";
import "@rivera/strategies/cake/interfaces/libraries/ITickMathLib.sol";



///@dev
///As there is dependency on Cake swap protocol. Replicating the protocol deployment on separately is difficult. Hence we would test on main net fork of BSC.
///The addresses used below must also be mainnet addresses.

contract CakeLpStakingV2Test is Test {
    CakeLpStakingV2 strategy;
    RiveraAutoCompoundingVaultV2Public vault;

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
    address _stake = 0x36696169C63e42cd08ce11f5deeBbCeBae652050;  //Mainnet address of the CAKE-USDT LP Pool you're deploying funds to. It is also the ERC20 token contract of the LP token.
    address _chef = 0x556B9306565093C855AEA9AE92A594704c2Cd59e;   //Address of the pancake master chef v2 contract on BSC mainnet
    address _factory = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;
    address _router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4; //Address of Pancake Swap router
    address _nonFungiblePositionManager = 0x46A15B0b27311cedF172AB29E4f4766fbE7F4364;
    address _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;   //Adress of the CAKE ERC20 token on mainnet
    address _usdt = 0x55d398326f99059fF775485246999027B3197955;

    //cakepool params
    bool _isTokenZeroDeposit = true;
    int24 _tickLower = -61000;
    int24 _tickUpper = -53000;
    address _cakeReward = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    //libraries
    address _tickMathLib = 0xbA839d70B635A27bB0481731C05c24aDa7Fc9Db9;
    address _sqrtPriceMathLib = 0xa16bEfe55b9Fa562bc99c03122E6b2a88301677B;
    address _liquidityMathLib = 0xD125f080CeeDc8950257d7209a9af715E13D56c0;
    address _safeCastLib = 0x4C79c18b90FE6F9051ba29CeC9CFC120564DCD98;
    address _liquidityAmountsLib = 0xBd9143688cB5E46d1a6d96bCf5833760f299cc4D;
    address _fullMathLib = 0x38D9e15E5AAD896e9be0214fCffc978b852F8A16;

    address[] _rewardToLp0AddressPath = [_cakeReward, _usdt];
    uint24[] _rewardToLp0FeePath = [2500];
    address[] _rewardToLp1AddressPath = [_cakeReward, _wbnb];
    uint24[] _rewardToLp1FeePath = [2500];

    ///@dev Vault Params
    ///@notice Can be configured according to preference
    string rivTokenName = "Riv CakeV2 WBNB-USDT";
    string rivTokenSymbol = "rivCakeV2WBNB-USDT";
    uint256 stratUpdateDelay = 21600;
    uint256 vaultTvlCap = 10000e18;

    ///@dev Users Setup
    address _manager = 0xA638177B9c3D96A30B75E6F9e35Baedf3f1954d2;
    address _user1 = 0x0A0e42Cb6FA85e78848aC241fACd8fCCbAc4962A;
    address _user2 = 0x2fa6a4D2061AD9FED3E0a1A7046dcc9692dA6Da8;
    address _whale = 0xD183F2BBF8b28d9fec8367cb06FE72B88778C86B;        //35 Mil whale 35e24
    uint256 _maxUserBal = 15e24;

    uint256 PERCENT_POOL_TVL_OF_CAPITAL = 5;
    uint256 minCapital = 1e18;      //One dollar of denomination asset

    function setUp() public {

        ///@dev all deployments will be made by the user
        vm.startPrank(_manager);

        ///@dev Initializing the vault with invalid strategy
        vault = new RiveraAutoCompoundingVaultV2Public(_usdt, rivTokenName, rivTokenSymbol, stratUpdateDelay, vaultTvlCap);

        ///@dev Initializing the strategy
        CommonAddresses memory _commonAddresses = CommonAddresses(address(vault), _router, _nonFungiblePositionManager);
        CakePoolParams memory cakePoolParams = CakePoolParams(
            _tickLower,
            _tickUpper,
            _stake,
            _chef,
            _cakeReward,
            _tickMathLib,
            _sqrtPriceMathLib,
            _liquidityMathLib,
            _safeCastLib,
            _liquidityAmountsLib,
            _fullMathLib,
            _rewardToLp0AddressPath,
            _rewardToLp0FeePath,
            _rewardToLp1AddressPath,
            _rewardToLp1FeePath
            );
        strategy = new CakeLpStakingV2(cakePoolParams, _commonAddresses);
        vault.init(IStrategy(address(strategy)));
        vm.stopPrank();

        ///@dev Transfering LP tokens from a whale to my accounts
        vm.startPrank(_whale);
        IERC20(_usdt).transfer(_user1, _maxUserBal);
        IERC20(_usdt).transfer(_user2, _maxUserBal);
        vm.stopPrank();
    }

    function test_GetDepositToken() public {
        address depositTokenAddress = strategy.getDepositToken();
        assertEq(depositTokenAddress, _usdt);
    }

    ///@notice tests for deposit function

    function test_DepositWhenNotPausedAndCalledByVaultForFirstTime(uint256 depositAmount) public {
        uint256 poolTvl = IERC20(_usdt).balanceOf(_stake) + strategy.convertAmount0ToAmount1(IERC20(_wbnb).balanceOf(_stake));
        emit log_named_uint("Total Pool TVL", poolTvl);
        vm.assume(depositAmount < PERCENT_POOL_TVL_OF_CAPITAL * poolTvl / 100 && depositAmount > minCapital);
        vm.prank(_user1);
        IERC20(_usdt).transfer(address(strategy), depositAmount);
        emit log_named_uint("strategy token id", strategy.tokenID());
        assertEq(strategy.tokenID(), 0);
        vm.prank(address(vault));
        strategy.deposit();
        assertTrue(strategy.tokenID()!=0);

        (uint128 liquidity, , int24 tickLower, int24 tickUpper, , , address user, , ) = IMasterChefV3(_chef).userPositionInfos(strategy.tokenID());
        assertTrue(liquidity!=0);
        assertEq(strategy.tickLower(), tickLower);
        assertEq(strategy.tickUpper(), tickUpper);
        emit log_named_address("user from position", user);
        assertEq(address(strategy), user);

        uint256 point5PercentOfDeposit = 5 * depositAmount / 1000;
        uint256 usdtBal = IERC20(_usdt).balanceOf(address(strategy));
        emit log_named_uint("After USDT balance", usdtBal);
        assertLt(usdtBal, point5PercentOfDeposit);

        uint256 point5PercentOfDepositInBnb = strategy.convertAmount0ToAmount1(point5PercentOfDeposit);
        uint256 wbnbBal = IERC20(_wbnb).balanceOf(address(strategy));
        emit log_named_uint("After WBNB balance", wbnbBal);
        assertLt(wbnbBal, 5);

        uint256 stratStakeBalanceAfter = strategy.balanceOf();
        emit log_named_uint("Total assets of strat", stratStakeBalanceAfter);
        assertApproxEqRel(stratStakeBalanceAfter, depositAmount, 5e17);     //Checks if the percentage difference between them is less than 0.5
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

    function _depositDenominationAsset(uint256 depositAmount) internal {        //Function to call in other tests that brings the vault to an already deposited state
        uint256 poolTvl = IERC20(_usdt).balanceOf(_stake) + strategy.convertAmount0ToAmount1(IERC20(_wbnb).balanceOf(_stake));
        vm.assume(depositAmount < PERCENT_POOL_TVL_OF_CAPITAL * poolTvl / 100 && depositAmount > minCapital);
        vm.prank(_user1);
        IERC20(_usdt).transfer(address(strategy), depositAmount);
        vm.prank(address(vault));
        strategy.deposit();
    }

    function _performSwapInBothDirections(uint256 swapAmount) internal {
        uint256 poolTvl = IERC20(_usdt).balanceOf(_stake) + strategy.convertAmount0ToAmount1(IERC20(_wbnb).balanceOf(_stake));
        vm.assume(swapAmount < PERCENT_POOL_TVL_OF_CAPITAL * poolTvl / 100 && swapAmount > minCapital);
        vm.startPrank(_user2);
        uint256 _wbnbReceived = IV3SwapRouter(_router).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                _usdt,
                _wbnb,
                strategy.poolFee(),
                _user2,
                swapAmount,
                0,
                0
            )
        );

        IV3SwapRouter(_router).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                _wbnb,
                _usdt,
                strategy.poolFee(),
                _user2,
                _wbnbReceived,
                0,
                0
            )
        );
        vm.stopPrank();
    }

    function test_BurnAndCollectV3(uint256 depositAmount, uint256 swapAmount) public {
        _depositDenominationAsset(depositAmount);
        vm.warp(block.timestamp + 7*24*60*60);
        _performSwapInBothDirections(swapAmount);

        (uint128 liquidity, , int24 tickLower, int24 tickUpper, , , address user, , ) = IMasterChefV3(_chef).userPositionInfos(strategy.tokenID());
        assertTrue(liquidity!=0);
        assertEq(strategy.tickLower(), tickLower);
        assertEq(strategy.tickUpper(), tickUpper);
        assertEq(address(strategy), user);

        uint256 tokenId = strategy.tokenID();
        ( , , , , , tickLower, tickUpper, liquidity, , , , ) = INonfungiblePositionManager(strategy.NonfungiblePositionManager()).positions(tokenId);
        assertTrue(liquidity!=0);
        assertEq(strategy.tickLower(), tickLower);
        assertEq(strategy.tickUpper(), tickUpper);

        uint256 cakeRewardsAvailable = strategy.rewardsAvailable();
        assertTrue(cakeRewardsAvailable!=0);

        ( , , , , , , , , , ,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = INonfungiblePositionManager(strategy.NonfungiblePositionManager()).positions(tokenId);
        assertTrue(tokensOwed0!=0);
        assertTrue(tokensOwed1!=0);

        address ownerNonFunLiq = INonfungiblePositionManager(strategy.NonfungiblePositionManager()).ownerOf(tokenId);
        assertEq(address(strategy), ownerNonFunLiq);

        strategy._burnAndCollectV3();

        (liquidity, , tickLower, tickUpper, , , user, , ) = IMasterChefV3(_chef).userPositionInfos(strategy.tokenID());
        assertEq(0, liquidity);
        assertEq(0, tickLower);
        assertEq(0, tickUpper);
        assertEq(address(0), user);

        ( , , , , , tickLower, tickUpper, liquidity, , , , ) = INonfungiblePositionManager(strategy.NonfungiblePositionManager()).positions(tokenId);
        assertEq(0, liquidity);
        assertEq(0, tickLower);
        assertEq(0, tickUpper);

        cakeRewardsAvailable = strategy.rewardsAvailable();
        assertEq(0, cakeRewardsAvailable);

        ( , , , , , , , , , ,
            tokensOwed0,
            tokensOwed1
        ) = INonfungiblePositionManager(strategy.NonfungiblePositionManager()).positions(tokenId);
        assertEq(0, tokensOwed0);
        assertEq(0, tokensOwed1);

        vm.expectRevert("ERC721: invalid token ID");
        INonfungiblePositionManager(strategy.NonfungiblePositionManager()).ownerOf(tokenId);
    }

    function test_ConvertAmount0ToAmount1(uint256 amount) public {
        uint256 convertedAmount = strategy.convertAmount0ToAmount1(amount);
        IPancakeV3Pool pool = IPancakeV3Pool(_stake);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 calculatedAmount = IFullMathLib(_fullMathLib).mulDiv(IFullMathLib(_fullMathLib).mulDiv(amount, sqrtPriceX96, FixedPoint96.Q96), sqrtPriceX96, FixedPoint96.Q96);
        assertEq(convertedAmount, calculatedAmount);
    }

    function test_ConvertAmount1ToAmount0(uint256 amount) public {
        uint256 convertedAmount = strategy.convertAmount1ToAmount0(amount);
        IPancakeV3Pool pool = IPancakeV3Pool(_stake);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 calculatedAmount = IFullMathLib(_fullMathLib).mulDiv(IFullMathLib(_fullMathLib).mulDiv(amount, FixedPoint96.Q96, sqrtPriceX96), FixedPoint96.Q96, sqrtPriceX96);
        assertEq(convertedAmount, calculatedAmount);
    }

    ///@notice tests for withdraw function

    function test_WithdrawWhenCalledByVault(uint256 depositAmount) public {
        _depositDenominationAsset(depositAmount);
        uint256 withdrawAmount = depositAmount - strategy.poolFee() * depositAmount / 1e6;

        uint256 vaultDenominaionbal = IERC20(_usdt).balanceOf(address(vault));
        assertEq(0, vaultDenominaionbal);

        uint256 liquidityBalBefore = strategy.liquidityBalance();

        vm.prank(address(vault));
        strategy.withdraw(withdrawAmount);

        vaultDenominaionbal = IERC20(_usdt).balanceOf(address(vault));
        assertEq(withdrawAmount, vaultDenominaionbal);

        uint256 liquidityBalAfter = strategy.liquidityBalance();
        uint256 liqDelta = strategy.calculateLiquidityDeltaForAssetAmount(withdrawAmount);
        assertEq(liquidityBalAfter - liquidityBalBefore, liqDelta);

        uint256 point5PercentOfDeposit = 5 * depositAmount / 1000;
        uint256 usdtBal = IERC20(_usdt).balanceOf(address(strategy));
        emit log_named_uint("After USDT balance", usdtBal);
        assertEq(usdtBal, 0);

        uint256 point5PercentOfDepositInBnb = strategy.convertAmount0ToAmount1(point5PercentOfDeposit);
        uint256 wbnbBal = IERC20(_wbnb).balanceOf(address(strategy));
        emit log_named_uint("After WBNB balance", wbnbBal);
        assertEq(wbnbBal, 0);

    }

    function test_WithdrawWhenNotCalledByVault(uint256 depositAmount, address randomAddress) public {
        vm.assume(_isEoa(randomAddress) && randomAddress!=address(vault));
        _depositDenominationAsset(depositAmount);
        uint256 withdrawAmount = depositAmount - strategy.poolFee() * depositAmount / 1e6;

        vm.expectRevert("!vault");
        vm.prank(randomAddress);
        strategy.withdraw(withdrawAmount);

    }

    function _isEoa(address account) internal view returns (bool) {
        return account.code.length == 0;
    }

    function test_ChangeRangeWhenNotCalledByOwner(int24 tickLower, int24 tickUpper, address randomAddress, uint256 depositAmount) public {
        vm.assume(_isEoa(randomAddress) && randomAddress!=_manager);
        _depositDenominationAsset(depositAmount);

        vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank(randomAddress);
        strategy.changeRange(tickLower, tickUpper);
    }

    function test_ChangeRangeWithSameTicks(uint256 depositAmount) public {
        _depositDenominationAsset(depositAmount);

        vm.expectRevert("Range cannot be same");
        vm.startPrank(_manager);
        strategy.changeRange(_tickLower, _tickUpper);
    }

    function test_ChangeRangeWithLowerTickNotLessThanUpperTick(int24 tickLower, int24 tickUpper, uint256 depositAmount) public {
        vm.assume(!(tickLower < tickUpper));
        _depositDenominationAsset(depositAmount);

        // vm.expectRevert("TLU");
        vm.startPrank(_manager);
        strategy.changeRange(tickLower, tickUpper);
    }

    function test_ChangeRangeWithLowerTickNotGreaterThanMinTick(int24 tickLower, int24 tickUpper, uint256 depositAmount) public {
        vm.assume(!(tickLower >= ITickMathLib(_tickMathLib).MIN_TICK()));
        _depositDenominationAsset(depositAmount);

        // vm.expectRevert("TLM");
        vm.startPrank(_manager);
        strategy.changeRange(tickLower, tickUpper);
    }

    function test_ChangeRangeWithUpperTickNotLessThanOrEqualMaxTick(int24 tickLower, int24 tickUpper, uint256 depositAmount) public {
        vm.assume(!(tickUpper <= ITickMathLib(_tickMathLib).MAX_TICK()));
        _depositDenominationAsset(depositAmount);

        // vm.expectRevert("TUM");
        vm.startPrank(_manager);
        strategy.changeRange(tickLower, tickUpper);
    }

    function test_ChangeRangeWithTickNotMultipleOfTickSpacing(int24 tickLower, int24 tickUpper, uint256 depositAmount) public {
        int24 tickSpacing = IPancakeV3Pool(_stake).tickSpacing();
        vm.assume(!(tickLower % tickSpacing == 0 && tickUpper % tickSpacing == 0));
        _depositDenominationAsset(depositAmount);

        vm.expectRevert("Invalid Ticks");
        vm.startPrank(_manager);
        strategy.changeRange(tickLower, tickUpper);
    }

    function test_ChangeRangeWhenCalledByOwner(int24 tickLower, int24 tickUpper, uint256 depositAmount) public {
        int24 tickSpacing = IPancakeV3Pool(_stake).tickSpacing();
        vm.assume(tickLower < tickUpper);
        vm.assume(tickLower >= ITickMathLib(_tickMathLib).MIN_TICK());
        vm.assume(tickUpper <= ITickMathLib(_tickMathLib).MAX_TICK());
        vm.assume(tickLower % tickSpacing == 0 && tickUpper % tickSpacing == 0);
        vm.assume(!((tickLower == _tickLower) && (tickUpper == _tickUpper)));
        _depositDenominationAsset(depositAmount);

        (uint128 liquidity, , int24 tickLower_, int24 tickUpper_, , , address user, , ) = IMasterChefV3(_chef).userPositionInfos(strategy.tokenID());
        assertEq(_tickLower, tickLower_);
        assertEq(_tickUpper, tickUpper_);

        uint256 tokenIdBef = strategy.tokenID();

        vm.startPrank(_manager);
        strategy.changeRange(tickLower, tickUpper);

        assertEq(tickLower, strategy.tickLower());
        assertEq(tickUpper, strategy.tickUpper());

        (liquidity, , tickLower_, tickUpper_, , , user, , ) = IMasterChefV3(_chef).userPositionInfos(strategy.tokenID());
        assertEq(tickLower, tickLower_);
        assertEq(tickUpper, tickUpper_);

        assertTrue(tokenIdBef != strategy.tokenID());
        
        uint256 point5PercentOfDeposit = 5 * depositAmount / 1000;
        uint256 usdtBal = IERC20(_usdt).balanceOf(address(strategy));
        emit log_named_uint("After USDT balance", usdtBal);
        assertEq(usdtBal, 0);

        uint256 point5PercentOfDepositInBnb = strategy.convertAmount0ToAmount1(point5PercentOfDeposit);
        uint256 wbnbBal = IERC20(_wbnb).balanceOf(address(strategy));
        emit log_named_uint("After WBNB balance", wbnbBal);
        assertEq(wbnbBal, 0);
    }

    function _convertRewardToToken0(uint256 reward) internal view returns (uint256 amount0) {
        (address[] memory rewardToLp0AddressPath, uint24[] memory rewardToLp0FeePath) = strategy.getRewardToLp0Path();
        amount0 = reward;
        for (uint256 i = 0; i < rewardToLp0FeePath.length; i++) {
            uint24 fee = rewardToLp0FeePath[i];
            address token0 = rewardToLp0AddressPath[i];
            address token1 = rewardToLp0AddressPath[i+1];
            address pool = IPancakeV3Factory(_factory).getPool(token0, token1, fee);
            (uint160 sqrtPriceX96, , , , , , ) = IPancakeV3Pool(pool).slot0();
            if (token0 != IPancakeV3Pool(pool).token0()) {
                amount0 = IFullMathLib(_fullMathLib).mulDiv(IFullMathLib(_fullMathLib).mulDiv(amount0, FixedPoint96.Q96, sqrtPriceX96), FixedPoint96.Q96, sqrtPriceX96);
            } else {
                amount0 = IFullMathLib(_fullMathLib).mulDiv(IFullMathLib(_fullMathLib).mulDiv(amount0, sqrtPriceX96, FixedPoint96.Q96), sqrtPriceX96, FixedPoint96.Q96);
            }
        }
    }

    function _convertRewardToToken1(uint256 reward) internal view returns (uint256 amount1) {
        (address[] memory rewardToLp1AddressPath, uint24[] memory rewardToLp1FeePath) = strategy.getRewardToLp0Path();
        amount1 = reward;
        for (uint256 i = 0; i < rewardToLp1FeePath.length; i++) {
            uint24 fee = rewardToLp1FeePath[i];
            address token0 = rewardToLp1AddressPath[i];
            address token1 = rewardToLp1AddressPath[i+1];
            address pool = IPancakeV3Factory(_factory).getPool(token0, token1, fee);
            (uint160 sqrtPriceX96, , , , , , ) = IPancakeV3Pool(pool).slot0();
            if (token0 != IPancakeV3Pool(pool).token0()) {
                amount1 = IFullMathLib(_fullMathLib).mulDiv(IFullMathLib(_fullMathLib).mulDiv(amount1, FixedPoint96.Q96, sqrtPriceX96), FixedPoint96.Q96, sqrtPriceX96);
            } else {
                amount1 = IFullMathLib(_fullMathLib).mulDiv(IFullMathLib(_fullMathLib).mulDiv(amount1, sqrtPriceX96, FixedPoint96.Q96), sqrtPriceX96, FixedPoint96.Q96);
            }
        }
    }

    ///@notice tests for harvest functions

    function test_HarvestWhenNotPaused(uint256 depositAmount, uint256 swapAmount) public {
        _depositDenominationAsset(depositAmount);
        _performSwapInBothDirections(swapAmount);
        _performSwapInBothDirections(swapAmount);


        uint256 stratPoolBalanceBefore = strategy.balanceOf();
        emit log_named_uint("Total assets of strat", stratPoolBalanceBefore);
        assertApproxEqRel(stratPoolBalanceBefore, depositAmount, 5e17);     //Checks if the percentage difference between them is less than 0.5

        vm.warp(block.timestamp + 7*24*60*60);

        uint256 rewardsAvblBef = IMasterChefV3(_chef).pendingCake(strategy.tokenID());
        assertTrue(rewardsAvblBef!=0);

        ( , , , , , , , , , ,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = INonfungiblePositionManager(_nonFungiblePositionManager).positions(strategy.tokenID());
        assertTrue(tokensOwed0!=0);
        assertTrue(tokensOwed1!=0);

        uint256 liquidityBef = strategy.liquidityBalance();

        uint256 usdtBalBef = IERC20(_usdt).balanceOf(address(strategy));
        uint256 wbnbBalBef = IERC20(_wbnb).balanceOf(address(strategy));
        uint256 cakeBalBef = IERC20(_cakeReward).balanceOf(address(strategy));

        vm.expectEmit(true, false, false, false);
        emit StratHarvest(address(this), 0, 0); //We don't try to match the second and third parameter of the event. They're result of Pancake swap contracts, we trust the protocol to be correct.
        strategy.harvest();
        
        uint256 stratPoolBalanceAfter = strategy.balanceOf();
        assertGt(stratPoolBalanceAfter, stratPoolBalanceBefore);

        uint256 rewardsAvblAft = IMasterChefV3(_chef).pendingCake(strategy.tokenID());
        assertEq(0, rewardsAvblAft);

        ( , , , , , , , , , ,
            tokensOwed0,
            tokensOwed1
        ) = INonfungiblePositionManager(_nonFungiblePositionManager).positions(strategy.tokenID());
        assertEq(tokensOwed0, 0);
        assertEq(tokensOwed1, 0);

        uint256 liquidityAft = strategy.liquidityBalance();
        assertGt(liquidityAft, liquidityBef);

        assertLt(IERC20(_usdt).balanceOf(address(strategy)) - usdtBalBef, 5 * _convertRewardToToken0(rewardsAvblBef) / 1000);
        assertLt(IERC20(_wbnb).balanceOf(address(strategy)) - wbnbBalBef, 5 * _convertRewardToToken1(rewardsAvblBef) / 1000);
        assertLt(IERC20(_cakeReward).balanceOf(address(strategy)) - cakeBalBef, 5 * rewardsAvblBef / 1000);        //less than 0.5 percent of the cake rewards available is left uninvested

    }

    function test_HarvestWhenPaused() public {
        vm.prank(_manager);
        strategy.pause();
        vm.expectRevert("Pausable: paused");
        strategy.harvest();
    }

    // function test_BalanceOfStake() public {
    //     uint256 stratStakeBalanceBefore = strategy.balanceOfStake();
    //     assertEq(stratStakeBalanceBefore, 0);

    //     vm.prank(_user);
    //     IERC20(_stake).transfer(address(strategy), 1e18);

    //     uint256 stratStakeBalanceAfter = strategy.balanceOfStake();
    //     assertEq(stratStakeBalanceAfter, 1e18);
    // }

    // function test_BalanceOfPool() public {
    //     uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
    //     assertEq(stratPoolBalanceBefore, 0);

    //     vm.prank(_user);
    //     IERC20(_stake).transfer(address(strategy), 1e18);
    //     vm.prank(address(vault));
    //     strategy.deposit();

    //     uint256 stratPoolBalanceAfter = strategy.balanceOfPool();
    //     assertEq(stratPoolBalanceAfter, 1e18);
    // }

    // function test_BalanceOfStrategy() public {
    //     uint256 stratBalanceBefore = strategy.balanceOf();
    //     assertEq(stratBalanceBefore, 0);

    //     vm.prank(_user);
    //     IERC20(_stake).transfer(address(strategy), 1e18);

    //     vm.prank(_user);
    //     IERC20(_stake).transfer(address(strategy), 1e18);
    //     vm.prank(address(vault));
    //     strategy.deposit();

    //     uint256 stratBalanceAfter = strategy.balanceOf();
    //     assertEq(stratBalanceAfter, 2e18);
    // }

    // function test_SetPendingRewardsFunctionNameCalledByManager() public {
    //     assertEq(strategy.pendingRewardsFunctionName(), "");

    //     vm.prank(_manager);
    //     strategy.setPendingRewardsFunctionName("pendingCake");

    //     assertEq(strategy.pendingRewardsFunctionName(), "pendingCake");
    // }

    // function test_SetPendingRewardsFunctionNameNotCalledByManager() public {
    //     assertEq(strategy.pendingRewardsFunctionName(), "");

    //     vm.expectRevert("!manager");
    //     strategy.setPendingRewardsFunctionName("pendingCake");

    // }

    // function test_RewardsAvailable() public {
    //     assertEq(strategy.pendingRewardsFunctionName(), "");

    //     vm.prank(_manager);
    //     strategy.setPendingRewardsFunctionName("pendingCake");

    //     vm.prank(_user);
    //     IERC20(_stake).transfer(address(strategy), 1e18);
    //     vm.prank(address(vault));
    //     strategy.deposit();

    //     uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
    //     assertEq(stratPoolBalanceBefore, 1e18);

    //     vm.roll(block.number + 100);

    //     assertGt(strategy.rewardsAvailable(), 0);

    // }

    // function testFail_RewardsAvailableBeforeSettingFunctionName() public {
    //     vm.prank(_user);
    //     IERC20(_stake).transfer(address(strategy), 1e18);
    //     vm.prank(address(vault));
    //     strategy.deposit();

    //     uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
    //     assertEq(stratPoolBalanceBefore, 1e18);

    //     vm.roll(block.number + 100);

    //     assertGt(strategy.rewardsAvailable(), 0);
    // }

    // function test_RetireStratWhenCalledByVault() public {

    //     vm.prank(_user);
    //     IERC20(_stake).transfer(address(strategy), 1e18);
    //     vm.prank(address(vault));
    //     strategy.deposit();

    //     vm.prank(_user);
    //     IERC20(_stake).transfer(address(strategy), 1e18);

    //     uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
    //     assertEq(stratPoolBalanceBefore, 1e18);

    //     uint256 stratStakeBalanceBefore = strategy.balanceOfStake();
    //     assertEq(stratStakeBalanceBefore, 1e18);

    //     uint256 vaultStakeBalanceBefore = IERC20(_stake).balanceOf(address(vault));
    //     assertEq(vaultStakeBalanceBefore, 0);

    //     vm.prank(address(vault));
    //     strategy.retireStrat();

    //     uint256 stratPoolBalanceAfterr = strategy.balanceOfPool();
    //     assertEq(stratPoolBalanceAfterr, 0);

    //     uint256 stratStakeBalanceAfter = strategy.balanceOfStake();
    //     assertEq(stratStakeBalanceAfter, 0);

    //     uint256 vaultStakeBalanceAfter = IERC20(_stake).balanceOf(address(vault));
    //     assertEq(vaultStakeBalanceAfter, 2e18);

    // }

    // function test_RetireStratWhenNotCalledByVault() public {

    //     vm.prank(_user);
    //     IERC20(_stake).transfer(address(strategy), 1e18);
    //     vm.prank(address(vault));
    //     strategy.deposit();

    //     vm.prank(_user);
    //     IERC20(_stake).transfer(address(strategy), 1e18);

    //     uint256 stratPoolBalanceBefore = strategy.balanceOfPool();
    //     assertEq(stratPoolBalanceBefore, 1e18);

    //     uint256 stratStakeBalanceBefore = strategy.balanceOfStake();
    //     assertEq(stratStakeBalanceBefore, 1e18);

    //     uint256 vaultStakeBalanceBefore = IERC20(_stake).balanceOf(address(vault));
    //     assertEq(vaultStakeBalanceBefore, 0);

    //     vm.expectRevert("!vault");
    //     strategy.retireStrat();

    // }

    // function test_PanicWhenCalledByManager() public {
    //     vm.prank(_manager);
    //     strategy.panic();

    //     assertEq(strategy.paused(), true);

    //     assertEq(IERC20(_stake).allowance(address(strategy), _chef), 0);
    //     assertEq(IERC20(_cake).allowance(address(strategy), _router), 0);
    //     assertEq(IERC20(_wom).allowance(address(strategy), _router), 0);
    //     assertEq(IERC20(_busd).allowance(address(strategy), _router), 0);
    // }

    // function test_PanicWhenNotCalledByManager() public {
    //     vm.expectRevert("!manager");
    //     strategy.panic();
    // }

    // function test_UnpauseWhenCalledByManager() public {
    //     vm.prank(_manager);
    //     strategy.panic();

    //     assertEq(strategy.paused(), true);

    //     assertEq(IERC20(_stake).allowance(address(strategy), _chef), 0);
    //     assertEq(IERC20(_cake).allowance(address(strategy), _router), 0);
    //     assertEq(IERC20(_wom).allowance(address(strategy), _router), 0);
    //     assertEq(IERC20(_busd).allowance(address(strategy), _router), 0);

    //     vm.prank(_manager);
    //     strategy.unpause();

    //     assertEq(strategy.paused(), false);

    //     assertEq(IERC20(_stake).allowance(address(strategy), _chef), type(uint256).max);
    //     assertEq(IERC20(_cake).allowance(address(strategy), _router), type(uint256).max);
    //     assertEq(IERC20(_wom).allowance(address(strategy), _router), type(uint256).max);
    //     assertEq(IERC20(_busd).allowance(address(strategy), _router), type(uint256).max);
    // }

    // function test_UnpauseWhenNotCalledByManager() public {
    //     vm.expectRevert("!manager");
    //     strategy.unpause();
    // }
}