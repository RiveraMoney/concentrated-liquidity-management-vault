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

    function setUp() public {
        _underlying_ = address(new ERC20Mock("MockERC20", "MockERC20", address(this), 0));
        RiveraAutoCompoundingVaultV2Public myVault = new RiveraAutoCompoundingVaultV2Public(_underlying_, "MockERC4626", "MockERC4626", 172800, type(uint256).max);
        _vault_ = address(myVault);
        address _strategy_ = address(new GenericStrategyMock(_underlying_, _vault_));
        myVault.init(IStrategy(_strategy_));
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

    function _isEOA     (address account) internal view returns (bool) { return account.code.length == 0; }
    
}
