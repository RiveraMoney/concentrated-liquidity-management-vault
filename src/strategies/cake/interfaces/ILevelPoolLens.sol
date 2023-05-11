pragma solidity ^0.8.0;

interface ILevelPoolLens {
    struct PositionView {
        bytes32 key;
        uint256 size;
        uint256 collateralValue;
        uint256 entryPrice;
        uint256 pnl;
        uint256 reserveAmount;
        bool hasProfit;
        address collateralToken;
        uint256 borrowIndex;
    }

    function getPosition(
        address _pool,
        address _owner,
        address _indexToken,
        address _collateralToken,
        uint8 _side
    ) external view returns (PositionView memory result);
}
