// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {RiveraAutoCompoundingVaultV2} from "@rivera/vaults/RiveraAutoCompoundingVaultV2.sol";

contract RiveraAutoCompoundingVaultV2Public is RiveraAutoCompoundingVaultV2 {

    constructor (
        address asset_,
        string memory _name,
        string memory _symbol,
        uint256 _approvalDelay, 
        uint256 _totalTvlCap
    ) RiveraAutoCompoundingVaultV2(asset_, _name, _symbol, _approvalDelay, _totalTvlCap) {}

    ///@dev hook function for access control of the vault. Has to be overriden in inheriting contracts to only give access for relevant parties.
    function _restrictAccess() internal view override {

    }

}