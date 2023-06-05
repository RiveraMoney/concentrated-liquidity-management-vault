pragma solidity ^0.8.0;

interface IVenusDistribution {
    function enterMarkets(
        address[] calldata vTokens
    ) external returns (uint[] memory);

    function getAccountLiquidity(
        address account
    ) external view returns (uint, uint, uint);

    function markets(
        address vTokenAddress
    ) external view returns (bool, uint, bool);
}
