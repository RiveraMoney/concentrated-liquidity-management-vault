// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc4626-tests/ERC4626.test.sol";
import "@rivera/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@rivera/strategies/common/GenericStrategyMock.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract RiveraAutoCompoundingVaultV2Test is ERC4626Test {

    address internal _strategy_;

    function setUp() public override {
        _underlying_ = address(new ERC20Mock("MockERC20", "MockERC20", address(this), 0));
        RiveraAutoCompoundingVaultV2Public myVault = new RiveraAutoCompoundingVaultV2Public(_underlying_, "MockERC4626", "MockERC4626", 172800, type(uint256).max);
        _vault_ = address(myVault);
        _strategy_ = address(new GenericStrategyMock(_underlying_, _vault_));
        myVault.init(IStrategy(_strategy_));
        _delta_ = 0;
        _vaultMayBeEmpty = false;
        _unlimitedAmount = true;
        console.logString("Set up done");
    }

    // setup initial vault state as follows:
    //
    // totalAssets == sum(init.share) + init.yield
    // totalShares == sum(init.share)
    //
    // init.user[i]'s assets == init.asset[i]
    // init.user[i]'s shares == init.share[i]
    function setUpVault(Init memory init) public override {
        console.logString("Entered setUpVault!");
        // setup initial shares and assets for individual users
        for (uint i = 0; i < N; i++) {
            address user = init.user[i];
            vm.assume(_isEOA(user));
            // shares
            uint shares = init.share[i];
            try IMockERC20(_underlying_).mint(user, shares) {} catch { vm.assume(false); }
            console.logString("Minted underlying!");
            _approve(_underlying_, user, _vault_, shares);
            vm.prank(user); try IERC4626(_vault_).deposit(shares, user) {} catch { vm.assume(false); }
            console.logString("Deposited in vault!");
            // assets
            uint assets = init.asset[i];
            try IMockERC20(_underlying_).mint(user, assets) {} catch { vm.assume(false); }
        }

        // setup initial yield for vault
        setUpYield(init);
    }

    // setup initial yield
    function setUpYield(Init memory init) public override {
        uint gain = uint(init.yield);
        try IMockERC20(_underlying_).mint(_strategy_, gain) {} catch { vm.assume(false); } // this can be replaced by calling yield generating functions if provided by the vault
    }

}
