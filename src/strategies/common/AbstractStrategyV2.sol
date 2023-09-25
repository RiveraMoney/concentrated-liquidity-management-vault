pragma solidity ^0.8.0;

import "@openzeppelin/access/Ownable2Step.sol";
import "@openzeppelin/security/Pausable.sol";

abstract contract AbstractStrategyV2 is Ownable2Step, Pausable {
    // common addresses for the strategy
    address public vault;
    address public router;
    address public manager;
    address public NonfungiblePositionManager;
    address private _pendingManager;

    event SetManager(address manager);

    //Modifier to restrict access to only vault
    function onlyVault() public view {
        require(msg.sender == vault, "!vault");
    }

    // checks that caller is either owner or manager.
    function onlyManager() public view {
        require(msg.sender == manager, "!manager");
    }

 
    function setManager(address _manager) external {
        onlyManager();
        require(_manager != address(0), "IA");//invalid address
        _pendingManager = _manager;
        // emit SetManager(_manager);
    }

    function renounceOwnership() public override onlyOwner {
        revert("ROD");//Renounce ownership disabled
    }

    function _transferManagership(address newManager) internal virtual {
        delete _pendingManager;
        manager = newManager;
        emit SetManager(newManager);
    }

    function acceptManagership() external {
        require(_pendingManager == msg.sender, "CINNM");//Caller Is Not New Manager
        _transferManagership(msg.sender);
    }
}
