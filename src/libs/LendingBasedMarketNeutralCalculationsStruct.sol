pragma solidity ^0.8.0;

struct LendingParams {
    bool isToken0Deposit;
    bool forDeposit;
    uint256 amount;
    uint256 safetyFactor;
    uint256 MANTISSA;
    address fullMathLib;
    address vTokenDep;
    address vTokenNeu;
    address distribution;
    address strat;
}