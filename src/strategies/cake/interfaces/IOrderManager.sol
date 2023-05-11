// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Interface for OrderManager Contract.:
 */

interface IOrderManager {
    function placeOrder(
        uint8,
        uint8,
        address,
        address,
        uint8,
        bytes calldata
    ) external;

    function pool() external view returns (address);
}
