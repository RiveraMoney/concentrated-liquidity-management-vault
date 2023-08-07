pragma solidity ^0.8.0;

import "./AbstractStrategyV2.sol";

contract FeeManager is AbstractStrategyV2 {

    uint256 public withdrawFeeDecimals;
    uint256 public withdrawFee;

    uint256 public feeDecimals;
    uint256 public protocolFee;
    uint256 public fundManagerFee;
    uint256 public partnerFee;
    address public partner;
}