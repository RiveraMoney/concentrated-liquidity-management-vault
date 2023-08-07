// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/extensions/ERC4626.sol";

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/utils/math/SafeMath.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/ReentrancyGuard.sol";
import "@openzeppelin/proxy/utils/Initializable.sol";

import "../strategies/common/interfaces/IStrategy.sol";

import "forge-std/console.sol";

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

abstract contract RiveraAutoCompoundingVaultV2 is ERC4626, Ownable, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // The last proposed strategy to switch to.
    StratCandidate public stratCandidate;
    // The strategy currently in use by the vault.
    IStrategy public strategy;
    // The minimum time it has to pass before a strat candidate can be approved.
    uint256 public immutable approvalDelay;
    // The cap on the total TVL of the vault. If the current TVL + current assets deposit > total TVL the deposit function will revert
    uint public totalTvlCap;
    // The cap on the user TVL of the vault. If the current TVL + current assets deposit > total TVL the deposit function will revert
    mapping(address => uint256) public userTvlCap;

    event NewStratCandidate(address implementation);
    event UpgradeStrat(address implementation);
    event TvlCapChange(address indexed onwer_, uint256 oldTvlCap, uint256 newTvlCap);
    event UserTvlCapChange(address indexed onwer_, address indexed user, uint256 oldTvlCap, uint256 newTvlCap);
    event SharePriceChange(uint256 sharePriceX96, uint256 unutilizedAssetBal);

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
        uint256 _approvalDelay, 
        uint256 _totalTvlCap
    ) ERC4626(IERC20Metadata(asset_)) ERC20(_name, _symbol) {
        approvalDelay = _approvalDelay;
        totalTvlCap = _totalTvlCap;
    }

    function init(IStrategy _strategy) public initializer {
        strategy = _strategy;
    }

    ///@dev hook function for access control of the vault. Has to be overriden in inheriting contracts to only give access for relevant parties.
    function _restrictAccess() internal view virtual {

    }

    /**
     * @dev Fetches the total assets held by the vault.
     * @return totalAssets the total balance of assets held by the vault.
     */
    function totalAssets() public view virtual override returns (uint256) {
        return strategy.balanceOf();
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address receiver) public view virtual override returns (uint256) {       //Can be decided both by total vault cap and user specific cap. If paused return 0
        if (strategy.paused()) return 0;
        uint256 maxFromTotalTvlCap = totalTvlCap - totalAssets();
        uint256 userCap = userTvlCap[receiver];
        uint256 maxFromUserTvlCap = userCap > 0? userTvlCap[receiver] - previewMint(balanceOf(receiver)): type(uint256).max;
        return maxFromTotalTvlCap < maxFromUserTvlCap ? maxFromTotalTvlCap : maxFromUserTvlCap;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address receiver) public view virtual override returns (uint256) {
        if (strategy.paused()) return 0;
        uint256 maxFromTotalTvlCap = this.convertToShares(totalTvlCap - this.totalAssets());
        uint256 userCap = userTvlCap[receiver];
        uint256 maxFromUserTvlCap = userCap > 0? convertToShares(userTvlCap[receiver]) - balanceOf(receiver): type(uint256).max;
        return maxFromTotalTvlCap < maxFromUserTvlCap ? maxFromTotalTvlCap : maxFromUserTvlCap;
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
        _restrictAccess();
        // strategy.beforeDeposit();

        IERC20(asset()).safeTransferFrom(caller, address(this), assets);
        _earn();
        _mint(receiver, shares);

        uint256 scaler = 2**96;
        emit SharePriceChange(assets * scaler / shares, IERC20(asset()).balanceOf(address(this)));
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
        _restrictAccess();
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

        uint256 scaler = 2**96;
        emit SharePriceChange(assets * scaler / shares, IERC20(asset()).balanceOf(address(this)));
        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function setTotalTvlCap(uint256 totalTvlCap_) external {
        _checkOwner();
        require(totalTvlCap != totalTvlCap_, "Same TVL cap");
        emit TvlCapChange(owner(), totalTvlCap, totalTvlCap_);
        totalTvlCap = totalTvlCap_;
    }

    function setUserTvlCap(address user_, uint256 userTvlCap_) external {
        _checkOwner();
        require(userTvlCap[user_] != userTvlCap_, "Same User cap");
        emit UserTvlCapChange(owner(), user_, userTvlCap[user_], userTvlCap_);
        userTvlCap[user_] = userTvlCap_;
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
