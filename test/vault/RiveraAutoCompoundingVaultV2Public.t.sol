// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/strategies/common/GenericStrategyMock.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IMockERC20 is IERC20 {
    function mint(address to, uint value) external;
    function burn(address from, uint value) external;
}

contract RiveraAutoCompoundingVaultV2PublicTest is Test  {

    address public _vault_;
    address public _underlying_;
    address public _owner_;

    event TvlCapChange(address indexed onwer_, uint256 oldTvlCap, uint256 newTvlCap);
    event UserTvlCapChange(address indexed onwer_, address indexed user, uint256 oldTvlCap, uint256 newTvlCap);

    function setUp() public {
        _underlying_ = address(new ERC20Mock("MockERC20", "MockERC20", address(this), 0));
        RiveraAutoCompoundingVaultV2Public myVault = new RiveraAutoCompoundingVaultV2Public(_underlying_, "MockERC4626", "MockERC4626", 172800, type(uint256).max);
        _vault_ = address(myVault);
        address _strategy_ = address(new GenericStrategyMock(_underlying_, _vault_));
        myVault.init(IStrategy(_strategy_));
        _owner_ = myVault.owner();
    }
    
    function setUpVault(address user, uint depositedAssets, uint256 userAssets, int yield_) public virtual {
        vm.assume(_isEOA(user));
        try IMockERC20(_underlying_).mint(user, depositedAssets) {} catch { vm.assume(false); }
        vm.prank(user);IMockERC20(_underlying_).approve(_vault_, depositedAssets);
        vm.prank(user); try IERC4626(_vault_).deposit(depositedAssets, user) {} catch { vm.assume(false); }
        try IMockERC20(_underlying_).mint(user, userAssets) {} catch { vm.assume(false); }
        // setup initial yield for vault
        setUpYield(yield_);
    }

    function setUpVaultNoDeposit(address user, uint256 userAssets) public virtual {
        vm.assume(_isEOA(user));
        try IMockERC20(_underlying_).mint(user, userAssets) {} catch { vm.assume(false); }
    }

    // setup initial yield
    function setUpYield(int _yield_) public virtual {
        if (_yield_ >= 0) { // gain
            uint gain = uint(_yield_);
            try IMockERC20(_underlying_).mint(_vault_, gain) {} catch { vm.assume(false); } // this can be replaced by calling yield generating functions if provided by the vault
        } else { // loss
            vm.assume(_yield_ > type(int).min); // avoid overflow in conversion
            uint loss = uint(-1 * _yield_);
            try IMockERC20(_underlying_).burn(_vault_, loss) {} catch { vm.assume(false); } // this can be replaced by calling yield generating functions if provided by the vault
        }
    }

    //Tests the property that any user can deposit
    function test_deposit(address user, uint depositedAssets, uint256 userAssets, int yield) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);        
        vm.prank(user); IERC4626(_vault_).deposit(userAssets, user);
    }

    //Tests the property that any user can mint
    function test_mint(address user, uint depositedAssets, uint256 userAssets, int yield, uint256 shares) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        shares = bound(shares, 0, IERC4626(_vault_).convertToShares(IERC20(_underlying_).balanceOf(user)));
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);        
        vm.prank(user); IERC4626(_vault_).mint(shares, user);
    }

    //
    // withdraw
    //

    function test_withdraw(address user, uint depositedAssets, uint256 userAssets, int yield) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        depositedAssets = bound(depositedAssets, 0, IERC4626(_vault_).convertToAssets(IERC20(_vault_).balanceOf(user)));
        vm.prank(user); IERC4626(_vault_).withdraw(depositedAssets, user, user);
    }

    //
    // redeem
    //

    function test_redeem(address user, uint depositedAssets, uint256 userAssets, int yield, uint256 shares) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        shares = bound(shares, 0, IERC20(_vault_).balanceOf(user));
        vm.prank(user); IERC4626(_vault_).redeem(shares, user, user);
    }

    // Limit Cap Tests
    // Deposit
    //Total Vault Cap
    function test_deposit_total_vault_cap(address user, uint256 userAssets) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.assume(IERC4626(_vault_).totalAssets() + userAssets >= 1);
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setTotalTvlCap(IERC4626(_vault_).totalAssets() + userAssets - 1);
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        vm.expectRevert("Vault Cap Breach!");
        vm.prank(user); IERC4626(_vault_).deposit(userAssets, user);
    }

    function test_deposit_total_vault_cap_always_greater(address user, uint256 userAssets, uint256 tvlCap) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        vm.assume(tvlCap >= IERC4626(_vault_).totalAssets());
        vm.assume(tvlCap != type(uint256).max);
        userAssets = bound(userAssets, 0, tvlCap - IERC4626(_vault_).totalAssets());
        vm.expectEmit(true, false, false, true);
        emit TvlCapChange(_owner_, type(uint256).max, tvlCap);
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setTotalTvlCap(tvlCap);
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        vm.prank(user); IERC4626(_vault_).deposit(userAssets, user);
        assertEq(tvlCap, RiveraAutoCompoundingVaultV2Public(_vault_).totalTvlCap());
        assertGe(tvlCap, IERC4626(_vault_).totalAssets());
    }

    function test_set_total_vault_cap_only_owner(address user, uint256 userAssets, uint256 tvlCap) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.assume(tvlCap != type(uint256).max);
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setTotalTvlCap(tvlCap);
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user); RiveraAutoCompoundingVaultV2Public(_vault_).setTotalTvlCap(tvlCap);
    }

    function test_same_total_vault_cap(address user, uint256 userAssets, uint256 tvlCap) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.assume(tvlCap != type(uint256).max);
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setTotalTvlCap(tvlCap);
        vm.expectRevert("Same TVL cap");
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setTotalTvlCap(tvlCap);
    }

    //User Vault Cap
    function test_deposit_user_vault_cap(address user, uint256 userAssets) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        vm.assume(IERC4626(_vault_).convertToAssets(IERC4626(_vault_).balanceOf(user)) + userAssets > 1);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setUserTvlCap(user, IERC4626(_vault_).convertToAssets(IERC4626(_vault_).balanceOf(user)) + userAssets - 1);
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        vm.expectRevert("User Cap Breach!");
        vm.prank(user); IERC4626(_vault_).deposit(userAssets, user);
    }

    function test_deposit_user_vault_cap_always_greater(address user, uint256 userAssets, uint256 userCap) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        vm.assume(userCap >= IERC4626(_vault_).convertToAssets(IERC4626(_vault_).balanceOf(user)));
        vm.assume(userCap != 0);
        userAssets = bound(userAssets, 0, userCap - IERC4626(_vault_).convertToAssets(IERC4626(_vault_).balanceOf(user)));
        vm.expectEmit(true, true, false, true);
        emit UserTvlCapChange(_owner_, user, 0, userCap);
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setUserTvlCap(user, userCap);
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        vm.prank(user); IERC4626(_vault_).deposit(userAssets, user);
        assertEq(userCap, RiveraAutoCompoundingVaultV2Public(_vault_).userTvlCap(user));
        assertGe(userCap, IERC4626(_vault_).convertToAssets(IERC4626(_vault_).balanceOf(user)));
    }

    function test_set_user_vault_cap_only_owner(address user, uint256 userAssets, uint256 userCap) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.assume(userCap != 0);
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setUserTvlCap(user, userCap);
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user); RiveraAutoCompoundingVaultV2Public(_vault_).setUserTvlCap(user, userCap);
    }

    function test_same_user_vault_cap(address user, uint256 userAssets, uint256 userCap) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.assume(userCap != 0);
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setUserTvlCap(user, userCap);
        vm.expectRevert("Same User cap");
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setUserTvlCap(user, userCap);
    }

    function test_deposit_user_vault_no_cap(address user, uint256 userAssets) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        vm.prank(user); IERC4626(_vault_).deposit(userAssets, user);
    }

    // Mint
    //Total Vault Cap
    function test_mint_total_vault_cap(address user, uint256 userAssets) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.assume(IERC4626(_vault_).totalAssets() + userAssets >= 1);
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setTotalTvlCap(IERC4626(_vault_).totalAssets() + userAssets - 1);
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        uint256 shares = IERC4626(_vault_).convertToShares(userAssets);
        vm.expectRevert("Vault Cap Breach!");
        vm.prank(user); IERC4626(_vault_).mint(shares, user);
    }

    function test_mint_total_vault_cap_always_greater(address user, uint256 userAssets, uint256 tvlCap) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        vm.assume(tvlCap >= IERC4626(_vault_).totalAssets());
        vm.assume(tvlCap != type(uint256).max);
        userAssets = bound(userAssets, 0, tvlCap - IERC4626(_vault_).totalAssets());
        vm.expectEmit(true, false, false, true);
        emit TvlCapChange(_owner_, type(uint256).max, tvlCap);
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setTotalTvlCap(tvlCap);
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        uint256 shares = IERC4626(_vault_).convertToShares(userAssets);
        vm.prank(user); IERC4626(_vault_).mint(shares, user);
        assertEq(tvlCap, RiveraAutoCompoundingVaultV2Public(_vault_).totalTvlCap());
        assertGe(tvlCap, IERC4626(_vault_).totalAssets());
    }

    //User Vault Cap
    function test_mint_user_vault_cap(address user, uint256 userAssets) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.assume(IERC4626(_vault_).convertToAssets(IERC4626(_vault_).balanceOf(user)) + userAssets > 1);
        vm.startPrank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setUserTvlCap(user, IERC4626(_vault_).convertToAssets(IERC4626(_vault_).balanceOf(user)) + userAssets - 1); vm.stopPrank();
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        uint256 shares = IERC4626(_vault_).convertToShares(userAssets);
        vm.expectRevert("User Cap Breach!");
        vm.prank(user); IERC4626(_vault_).mint(shares, user);
    }

    function test_mint_user_vault_cap_always_greater(address user, uint256 userAssets, uint256 userCap) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        vm.assume(userCap >= IERC4626(_vault_).convertToAssets(IERC4626(_vault_).balanceOf(user)));
        vm.assume(userCap != 0);
        userAssets = bound(userAssets, 0, userCap - IERC4626(_vault_).convertToAssets(IERC4626(_vault_).balanceOf(user)));
        vm.expectEmit(true, true, false, true);
        emit UserTvlCapChange(_owner_, user, 0, userCap);
        vm.prank(_owner_); RiveraAutoCompoundingVaultV2Public(_vault_).setUserTvlCap(user, userCap);
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        uint256 shares = IERC4626(_vault_).convertToShares(userAssets);
        vm.prank(user); IERC4626(_vault_).mint(shares, user);
        assertEq(userCap, RiveraAutoCompoundingVaultV2Public(_vault_).userTvlCap(user));
        assertGe(userCap, IERC4626(_vault_).convertToAssets(IERC4626(_vault_).balanceOf(user)));
    }

    function test_mint_user_vault_no_cap(address user, uint256 userAssets) public virtual {
        setUpVaultNoDeposit(user, userAssets);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        uint256 shares = IERC4626(_vault_).convertToShares(userAssets);
        vm.prank(user); IERC4626(_vault_).mint(shares, user);
    }

    function _isEOA(address account) internal view returns (bool) { return account.code.length == 0; }
    
}
