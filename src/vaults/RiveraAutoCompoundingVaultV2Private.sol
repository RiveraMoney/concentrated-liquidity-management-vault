// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {RiveraAutoCompoundingVaultV2} from "@rivera/vaults/RiveraAutoCompoundingVaultV2.sol";

contract RiveraAutoCompoundingVaultV2Private is RiveraAutoCompoundingVaultV2 {

    constructor (
        address asset_,
        string memory _name,
        string memory _symbol,
        uint256 _approvalDelay
    ) RiveraAutoCompoundingVaultV2(asset_, _name, _symbol, _approvalDelay) {}

    ///@dev hook function for access control of the vault. Has to be overriden in inheriting contracts to only give access for relevant parties.
    function _restrictAccess() internal view override {
        _checkOwner();
    }

}