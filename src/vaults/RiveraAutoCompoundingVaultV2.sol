// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../strategies/common/interfaces/IStrategy.sol";

/**
 * @dev Implementation of a vault to deposit funds for yield optimizing.
 * This is the contract that receives funds and that users interface with.
 * The yield optimizing strategy itself is implemented in a separate 'Strategy.sol' contract.
 * This improves over the previous version of the vault by making the vault ERC4626 compliant.
 */

struct StratCandidate {
        address implementation;
        uint proposedTime;
    }

contract RiveraAutoCompoundingVaultV2 is ERC4626, Ownable, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // The last proposed strategy to switch to.
    StratCandidate public stratCandidate;
    // The strategy currently in use by the vault.
    IStrategy public strategy;
    // The minimum time it has to pass before a strat candidate can be approved.
    uint256 public immutable approvalDelay;

    event NewStratCandidate(address implementation);
    event UpgradeStrat(address implementation);

    /*
     * @dev Sets the value of {token} to the token that the vault will
     * hold as underlying value. It initializes the vault's own 'moo' token.
     * This token is minted when someone does a deposit. It is burned in order
     * to withdraw the corresponding portion of the underlying assets.
     * @param _strategy the address of the strategy.
     * @param _name the name of the vault token.
     * @param _symbol the symbol of the vault token.
     * @param _approvalDelay the delay before a new strat can be approved.
     */
    constructor (
        address asset_,
        string memory _name,
        string memory _symbol,
        uint256 _approvalDelay
    ) ERC4626(IERC20Metadata(asset_)) ERC20(_name, _symbol) {
        approvalDelay = _approvalDelay;
    }

    function init(IStrategy _strategy) public initializer {
        strategy = _strategy;
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return strategy.stake();
    }

    /**
     * @dev Fetches the total assets held by the vault.
     * @return totalAssets the total balance of assets held by the vault.
     */
    function totalAssets() public view virtual override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)).add(IStrategy(strategy).balanceOf());
    }

    /**
     * @dev Function to send funds into the strategy and put them to work. It's primarily called
     * by the vault's deposit() function.
     */
    function _earn() internal { //Transfers all available funds to the strategy and deploys it to AAVE 
        IERC20 asset_ = IERC20(asset());
        asset_.safeTransfer(address(strategy), asset_.balanceOf(address(this)));
        strategy.deposit();
    }

    /**
     * @dev Deposit assets to the vault and mint an equal number of wrapped tokens to vault shares.
     * @param caller the address of the sender of the assets.
     * @param receiver the address of the receiver of the wrapped tokens.
     * @param assets the amount of assets being deposited.
     * @param shares the amount of shares being minted.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        strategy.beforeDeposit();

        IERC20(asset()).safeTransferFrom(caller, address(this), assets);
        _earn();
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Burn wrapped tokens and withdraw assets from the vault.
     * @param caller the address of the caller of the withdraw.
     * @param receiver the address of the receiver of the assets.
     * @param owner the address of the owner of the burnt shares.
     * @param assets the amount of assets being withdrawn.
     * @param shares the amount of shares being burnt.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        _burn(owner, shares);

        IERC20 asset_ = IERC20(asset());

        uint b = asset_.balanceOf(address(this)); //Balance of this vault contract address
        if (b < assets) { //If balance is greater than the amout that has to be sent to user can send directly no need to even touch strategy
            uint withdraw_ = assets.sub(b); //Extra amout that has to be withdrawn from strategy
            strategy.withdraw(withdraw_);
            uint _after = asset_.balanceOf(address(this)); //Inside the withdraw method strategy has already transfered the withdraw amount to vault
            uint _diff = _after.sub(b);
            if (_diff < withdraw_) { //For a normal token diff and withdraw should be same. For deflationary tokens we redifine r.
                assets = b.add(_diff);
            }
        }

        asset_.safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /** 
     * @dev Sets the candidate for the new strat to use with this vault.
     * @param _implementation The address of the candidate strategy.  
     */
    function proposeStrat(address _implementation) public {
        require(owner() == _msgSender() || strategy.manager() == _msgSender(), "!(owner || manager)");
        require(address(this) == IStrategy(_implementation).vault(), "!proposal"); //Stratey also holds the address of the vault hence equality should hold
        stratCandidate = StratCandidate({
            implementation: _implementation,
            proposedTime: block.timestamp
         }); //Sets the variable and emits event

        emit NewStratCandidate(_implementation);
    }

    function getStratProposal() public view returns (StratCandidate memory) {
        return stratCandidate;
    }

    /** 
     * @dev It switches the active strat for the strat candidate. After upgrading, the 
     * candidate implementation is set to the 0x00 address, and proposedTime to a time 
     * happening in +100 years for safety. 
     */

    function upgradeStrat() public { //Only owner can update strategy
        _checkOwner();
        require(stratCandidate.implementation != address(0), "!candidate"); //Strategy implementation has to be set before calling the method
        require(stratCandidate.proposedTime.add(approvalDelay) < block.timestamp, "!delay"); //Approval delay should have been passed since proposal time

        emit UpgradeStrat(stratCandidate.implementation);

        IStrategy prevStrategy = strategy;
        strategy = IStrategy(stratCandidate.implementation);
        stratCandidate.implementation = address(0); //Setting these values means that there is no proposal for new strategy
        stratCandidate.proposedTime = 5000000000;
        prevStrategy.retireStrat();
        _earn();
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external {
        _checkOwner();
        require(_token != asset(), "!token"); //Token must not be equal to address of stake currency

        uint256 amount = IERC20(_token).balanceOf(address(this)); //Just finding the balance of this vault contract address in the the passed token and transfers
        IERC20(_token).safeTransfer(msg.sender, amount);
    }
}
