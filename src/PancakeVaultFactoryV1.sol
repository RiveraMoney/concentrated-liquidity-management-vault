pragma solidity ^0.8.0;

import './interfaces/IRiveraAutoCompoundingVaultFactoryV1.sol';
import './interfaces/IPancakeFactory.sol';
import './strategies/cake/interfaces/IMasterChef.sol';
import './strategies/common/interfaces/IStrategy.sol';
import './vaults/RiveraAutoCompoundingVaultV1.sol';
import './strategies/cake/CakeLpStakingV1.sol';
import './strategies/common/AbstractStrategy.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract PancakeVaultFactoryV1 is IRiveraAutoCompoundingVaultFactoryV1, Ownable {

    ///@notice mapping address of the user who created it to address of the LP pool to pool id to vault address
    ///@dev The keys of this map would be unique for each vault in the protocol
    mapping(address => mapping(address => mapping(uint256 => address))) public getVault;
    address[] public allVaults;

    ///@notice fixed params that are required to deploy the pool
    address chef;
    address router;
    uint256 approvalDelay;
    address pancakeFactory;

    constructor(address _chef, address _router, uint256 _approvalDelay, address _pancakeFactory) {
        chef = _chef;
        router = _router;
        approvalDelay = _approvalDelay;
        pancakeFactory = _pancakeFactory;
    }

    function allVaultsLength() external view returns (uint) {
        return allVaults.length;
    }

    function createVault(CreateVaultParams memory createVaultParams) external returns (address vaultAddress) {
        address lpToken0 = createVaultParams.rewardToLp0Route[createVaultParams.rewardToLp0Route.length - 1];
        address lpToken1 = createVaultParams.rewardToLp1Route[createVaultParams.rewardToLp1Route.length - 1];
        require(IPancakeFactory(pancakeFactory).getPair(lpToken0, lpToken1) == createVaultParams.lpPool, 'RiveraPanCakeVaultFactoryV1: INVALID_POOL');
        require(IMasterChef(chef).poolLength() >= createVaultParams.poolId, 'RiveraPanCakeVaultFactoryV1: INVALID_POOL_ID');
        require(lpToken0 != address(0), 'RiveraPanCakeVaultFactoryV1: LP_TOKEN0_ZERO_ADDRESS');
        require(getVault[msg.sender][createVaultParams.lpPool][createVaultParams.poolId] == address(0), 'RiveraPanCakeVaultFactoryV1: VAULT_EXISTS'); // single check is sufficient
        RiveraAutoCompoundingVaultV1 vault = new RiveraAutoCompoundingVaultV1(createVaultParams.tokenName, createVaultParams.tokenSymbol, approvalDelay, address(this));
        vaultAddress = address(vault);
        CommonAddresses memory commonAddresses = CommonAddresses(vaultAddress, router, owner());
        CakePoolParams memory cakePoolParams = CakePoolParams(createVaultParams.lpPool, createVaultParams.poolId, chef, createVaultParams.rewardToLp0Route, createVaultParams.rewardToLp1Route);
        CakeLpStakingV1 strategy = new CakeLpStakingV1(cakePoolParams, commonAddresses);
        vault.init(IStrategy(address(strategy)));
        getVault[msg.sender][createVaultParams.lpPool][createVaultParams.poolId] = vaultAddress;
        allVaults.push(vaultAddress);
        emit VaultCreated(msg.sender, createVaultParams.lpPool, createVaultParams.poolId, vaultAddress);
    }

    function getVaultForCurrentUser(address lpPool, uint256 poolId) public view returns (address) {
        return getVault[msg.sender][lpPool][poolId];
    }

    function setChef(address _chef) external onlyOwner {
        chef = _chef;
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    function setApprovalDelay(uint256 _approvalDelay) external onlyOwner {
        approvalDelay = _approvalDelay;
    }

    function setPancakeFactory(address _pancakeFactory) external onlyOwner {
        pancakeFactory = _pancakeFactory;
    }

}
