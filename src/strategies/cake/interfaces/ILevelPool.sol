pragma solidity ^0.8.0;

struct Position {
    uint256 size;
    uint256 collateralValue;
    uint256 reserveAmount;
    uint256 entryPrice;
    uint256 borrowIndex;
}

interface ILevelPool {
    function positions(bytes32) external view returns (Position memory);
}
