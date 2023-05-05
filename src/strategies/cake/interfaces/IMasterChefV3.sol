pragma solidity ^0.8.0;
import "./INonfungiblePositionManager.sol";

interface IMasterChefV3 {
    function userPositionInfos(
        uint256
    )
        external
        view
        returns (
            uint128,
            uint128,
            int24,
            int24,
            uint256,
            uint256,
            address,
            uint256,
            uint256
        );

    function pendingCake(uint256 _tokenId) external view returns (uint256);

    function withdraw(
        uint256 _tokenId,
        address _to
    ) external returns (uint256 reward);

    function updateLiquidity(uint256 _tokenId) external;

    function harvest(
        uint256 _tokenId,
        address _to
    ) external returns (uint256 reward);

    function decreaseLiquidity(
        INonfungiblePositionManager.DecreaseLiquidityParams calldata params
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(
        INonfungiblePositionManager.CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);
}
