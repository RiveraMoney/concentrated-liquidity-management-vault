pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
    function vault() external view returns (address);
    function chef() external view returns (address);
    function stake() external view returns (IERC20);
    function reward() external view returns (IERC20);
    function lpToken0() external view returns (IERC20);
    function lpToken1() external view returns (IERC20);
    function beforeDeposit() external;
    function deposit() external;
    function withdraw(uint256) external;
    function balanceOf() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function harvest() external;
    function retireStrat() external;
    function panic() external;
    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
    function router() external view returns (address);
    function poolId() external view returns (uint256);
    function rewardToLp0Route(uint256) external view returns (address);
    function rewardToLp1Route(uint256) external view returns (address);
    function owner() external view returns (address);
}
