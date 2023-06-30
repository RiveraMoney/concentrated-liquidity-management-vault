pragma solidity ^0.8.0;

import "./AbstractStrategyV2.sol";

contract FeeManager is AbstractStrategyV2 {

    uint256 withdrawFeeDecimals;
    uint256 withdrawFee;

    uint256 feeDecimals;
    uint256 protocolFee;
    uint256 fundManagerFee;
    uint256 partnerFee;
    address partner;
}