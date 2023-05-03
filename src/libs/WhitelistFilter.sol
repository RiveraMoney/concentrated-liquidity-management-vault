// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract WhitelistFilter is Ownable {

    mapping(address => bool) public whitelist;

    event NewWhitelist(address indexed user, address indexed owner);
    event RemoveWhitelist(address indexed user, address indexed owner);

    function _checkWhitelist() internal view virtual {
        require(whitelist[msg.sender], "WhitelistFilter: !whitelisted");
    }

    function newWhitelist(address user) external virtual onlyOwner {
        require(!whitelist[user], "WhitelistFilter: Already Whitelisted");
        whitelist[user] = true;
        emit NewWhitelist(user, owner());
    }

    function removeWhitelist(address user) external virtual onlyOwner {
        require(whitelist[user], "WhitelistFilter: Removing Non Whitelisted");
        whitelist[user] = false;
        emit RemoveWhitelist(user, owner());
    }
}