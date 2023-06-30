pragma solidity ^0.8.0;

import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/Pausable.sol";

abstract contract AbstractStrategyV2 is Ownable, Pausable {
    // common addresses for the strategy
    address public vault;
    address public router;
    address public manager;
    address public NonfungiblePositionManager;

    event SetManager(address manager);

    //Modifier to restrict access to only vault
    function onlyVault() public view {
        require(msg.sender == vault, "!vault");
    }

    // checks that caller is either owner or manager.
    function onlyManager() public view {
        require(msg.sender == manager, "!manager");
    }

    // set new manager to manage strat
    function setManager(address _manager) external {
        onlyManager();
        manager = _manager;
        emit SetManager(_manager);
    }
}
