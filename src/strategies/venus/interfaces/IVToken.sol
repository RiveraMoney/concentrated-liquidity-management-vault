pragma solidity ^0.8.13;

interface IVToken {
    function mint(uint mintAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function borrowBalanceStored(address account) external returns (uint256);

    function totalSupply() external returns (uint);

    function repayBorrow(uint repayAmount) external returns (uint);

    ///found out

    function borrowBalanceCurrent(address account) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);
}