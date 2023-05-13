pragma solidity ^0.8.0;

import "@openzeppelin/security/Pausable.sol";
import "@rivera/strategies/common/interfaces/IStrategy.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract GenericStrategyMock is Pausable {
    using SafeERC20 for IERC20;

    address public stake;
    address public vault;
    address public manager;

    constructor (address _stake, address _vault) {
        stake = _stake;
        vault = _vault;
        manager = msg.sender;
    }

    event Deposit(uint256 tvl, uint256 amount);
    event Withdraw(uint256 tvl, uint256 amount);

    // calculate the total underlaying 'stake' held by the strat.
    function balanceOf() public view returns (uint256) {
        return IERC20(stake).balanceOf(address(this));
    }

    ///@dev this function intentionally does nothing. Yeild for the strategy contract is generated manually. It only exists to conform to the expectations of the vault contract.
    function deposit() public {
        uint256 stakeBal = IERC20(stake).balanceOf(address(this));
        if (stakeBal > 0) {
            emit Deposit(balanceOf(), stakeBal);
        }
    }

    function beforeDeposit() external virtual {}

    function withdraw(uint256 _amount) external {
        uint256 stakeBal = IERC20(stake).balanceOf(address(this));

        if (stakeBal > _amount) {
            stakeBal = _amount;
        }

        IERC20(stake).safeTransfer(vault, stakeBal);

        emit Withdraw(balanceOf(), stakeBal);
    }

}