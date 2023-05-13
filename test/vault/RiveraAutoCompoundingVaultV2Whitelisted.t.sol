// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/mocks/ERC20Mock.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Whitelisted.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/strategies/common/GenericStrategyMock.sol";
import {IERC4626} from "@openzeppelin/interfaces/IERC4626.sol";
import {WhitelistFilter} from "@rivera/libs/WhitelistFilter.sol";

interface IMockERC20 is IERC20 {
    function mint(address to, uint value) external;
    function burn(address from, uint value) external;
}

contract RiveraAutoCompoundingVaultV2WhitelistedTest is Test  {

    address public _vault_;
    address public _underlying_;
    address public immutable _zero_address_ = address(0);
    address public _owner_;

    event NewWhitelist(address indexed user, address indexed owner);
    event RemoveWhitelist(address indexed user, address indexed owner);

    function setUp() public {
        _underlying_ = address(new ERC20Mock("MockERC20", "MockERC20", address(this), 0));
        RiveraAutoCompoundingVaultV2Whitelisted myVault = new RiveraAutoCompoundingVaultV2Whitelisted(_underlying_, "MockERC4626", "MockERC4626", 172800, type(uint256).max);
        _vault_ = address(myVault);
        address _strategy_ = address(new GenericStrategyMock(_underlying_, _vault_));
        myVault.init(IStrategy(_strategy_));
        _owner_ = myVault.owner();
    }
    
    function setUpVault(address user, uint depositedAssets, uint256 userAssets, int yield_) public virtual {
        vm.assume(_isEOA(user));        //This will make sure the user address is never the same address as that of this contract
        vm.assume(user != _zero_address_);
        vm.prank(_owner_); WhitelistFilter(_vault_).newWhitelist(user);
        try IMockERC20(_underlying_).mint(user, depositedAssets) {} catch { vm.assume(false); }
        vm.prank(user);IMockERC20(_underlying_).approve(_vault_, depositedAssets);
        vm.prank(user); try IERC4626(_vault_).deposit(depositedAssets, user) {} catch { vm.assume(false); }
        try IMockERC20(_underlying_).mint(user, userAssets) {} catch { vm.assume(false); }
        // setup initial yield for vault
        setUpYield(yield_);
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

    //Tests the property that any user can deposit
    function test_deposit_not_whitelisted(address user, uint depositedAssets, uint256 userAssets, int yield) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        vm.prank(_owner_); WhitelistFilter(_vault_).removeWhitelist(user);
        userAssets = bound(userAssets, 0, IERC20(_underlying_).balanceOf(user));
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        vm.expectRevert("WhitelistFilter: !whitelisted");
        vm.prank(user); IERC4626(_vault_).deposit(userAssets, user);
    }

    //Tests the property that any user can mint
    function test_mint_not_whitelisted(address user, uint depositedAssets, uint256 userAssets, int yield, uint256 shares) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        vm.prank(_owner_); WhitelistFilter(_vault_).removeWhitelist(user);
        shares = bound(shares, 0, IERC4626(_vault_).convertToShares(IERC20(_underlying_).balanceOf(user)));
        vm.prank(user); IMockERC20(_underlying_).approve(_vault_, userAssets);
        vm.expectRevert("WhitelistFilter: !whitelisted");    
        vm.prank(user); IERC4626(_vault_).mint(shares, user);
    }

    //
    // withdraw
    //

    function test_withdraw_not_whitelisted(address user, uint depositedAssets, uint256 userAssets, int yield) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        vm.prank(_owner_); WhitelistFilter(_vault_).removeWhitelist(user);
        depositedAssets = bound(depositedAssets, 0, IERC4626(_vault_).convertToAssets(IERC20(_vault_).balanceOf(user)));
        vm.expectRevert("WhitelistFilter: !whitelisted");
        vm.prank(user); IERC4626(_vault_).withdraw(depositedAssets, user, user);
    }

    //
    // redeem
    //

    function test_redeem_not_whitelisted(address user, uint depositedAssets, uint256 userAssets, int yield, uint256 shares) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        vm.prank(_owner_); WhitelistFilter(_vault_).removeWhitelist(user);
        shares = bound(shares, 0, IERC20(_vault_).balanceOf(user));
        vm.expectRevert("WhitelistFilter: !whitelisted");
        vm.prank(user); IERC4626(_vault_).redeem(shares, user, user);
    }

    function test_newWhitelist(address user, uint depositedAssets, uint256 userAssets, int yield, address otherUser) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        vm.assume(_isEOA(otherUser));        //This will make sure the user address is never the same address as that of this contract
        vm.assume(otherUser != _zero_address_);
        vm.expectEmit(true, true, false, false);
        emit NewWhitelist(otherUser, _owner_);
        vm.prank(_owner_); WhitelistFilter(_vault_).newWhitelist(otherUser);
        assertTrue(WhitelistFilter(_vault_).whitelist(otherUser));
    } 

    function test_removeWhitelist(address user, uint depositedAssets, uint256 userAssets, int yield, address otherUser) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        vm.assume(_isEOA(otherUser));        //This will make sure the user address is never the same address as that of this contract
        vm.assume(otherUser != _zero_address_);
        vm.prank(_owner_); WhitelistFilter(_vault_).newWhitelist(otherUser);
        vm.expectEmit(true, true, false, false);
        emit RemoveWhitelist(otherUser, _owner_);
        vm.prank(_owner_); WhitelistFilter(_vault_).removeWhitelist(otherUser);
        assertFalse(WhitelistFilter(_vault_).whitelist(otherUser));
    } 

    function test_newWhitelist_not_owner(address user, uint depositedAssets, uint256 userAssets, int yield, address otherUser) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        vm.assume(_isEOA(otherUser));        //This will make sure the user address is never the same address as that of this contract
        vm.assume(otherUser != _zero_address_);
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user); WhitelistFilter(_vault_).newWhitelist(otherUser);
    } 

    function test_removeWhitelist_not_owner(address user, uint depositedAssets, uint256 userAssets, int yield, address otherUser) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        vm.assume(_isEOA(otherUser));        //This will make sure the user address is never the same address as that of this contract
        vm.assume(otherUser != _zero_address_);
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user); WhitelistFilter(_vault_).removeWhitelist(otherUser);
    } 

    function test_newWhitelist_again(address user, uint depositedAssets, uint256 userAssets, int yield, address otherUser) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        vm.assume(_isEOA(otherUser));        //This will make sure the user address is never the same address as that of this contract
        vm.assume(otherUser != _zero_address_);
        vm.prank(_owner_); WhitelistFilter(_vault_).newWhitelist(otherUser);
        vm.expectRevert("WhitelistFilter: Already Whitelisted");
        vm.prank(_owner_); WhitelistFilter(_vault_).newWhitelist(otherUser);
    } 

    function test_removeWhitelist_no_whitelist(address user, uint depositedAssets, uint256 userAssets, int yield, address otherUser) public virtual {
        setUpVault(user, depositedAssets, userAssets, yield);
        vm.assume(_isEOA(otherUser));        //This will make sure the user address is never the same address as that of this contract
        vm.assume(otherUser != _zero_address_);
        vm.expectRevert("WhitelistFilter: Removing Non Whitelisted");
        vm.prank(_owner_); WhitelistFilter(_vault_).removeWhitelist(otherUser);
    } 

    function _isEOA(address account) internal view returns (bool) { return account.code.length == 0; }
    
}
