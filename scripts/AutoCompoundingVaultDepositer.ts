import { ethers } from "hardhat";
var fs = require('fs');

import { default as vaultArtifact } from "../artifacts/src/vaults/RiveraAutoCompoundingVaultV1.sol/RiveraAutoCompoundingVaultV1.json";
const vaultAbi = vaultArtifact.abi;

const _FACTORY_CONTRACT_DEPLOYMENT_BLOCK = 23807246;    //Block at which the Rivera factory contract was deployed. It only makes sense to query for events from this block
const _common_deposit_amount = "10000000000000000000";

async function getVaultCreatedEventsFromFactory(factoryContract: ethers.Contract) {
    const vaultsFilter = factoryContract.filters.VaultCreated();
    const vaultsLogs = await factoryContract.queryFilter(vaultsFilter, _FACTORY_CONTRACT_DEPLOYMENT_BLOCK);
    let vaultEvents = vaultsLogs.map((log) => factoryContract.interface.parseLog(log));
    return vaultEvents;
}

//To keep the contract deployment address same always restart the blockchain before deploying, as the deployed contract address depends on the nonce
async function main() {

    const jsonString = fs.readFileSync('contractAddress.json');
    const pancakeVaultFactoryV1Address = JSON.parse(jsonString);

    const PancakeVaultFactoryV1 = await ethers.getContractFactory("PancakeVaultFactoryV1");
    const pancakeVaultFactoryV1 = await PancakeVaultFactoryV1.attach(pancakeVaultFactoryV1Address.contractAddress);
    const CakeLpStakingV1 = await ethers.getContractFactory("CakeLpStakingV1");
    const ERC20 = await ethers.getContractFactory("@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20");
    // const cakeBnb = ERC20.attach("0x0eD7e52944161450477ee417DE9Cd3a859b14fD0");
    // const cakeBusd = ERC20.attach("0x804678fa97d91B974ec2af3c843270886528a9E6");
    // const cakeUsdt = ERC20.attach("0xA39Af17CE4a8eb807E076805Da1e2B8EA7D0755b");

    const [user1, user2] = await ethers.getSigners();

    const vaultCreatedEvents = await getVaultCreatedEventsFromFactory(pancakeVaultFactoryV1);
    for (let i in vaultCreatedEvents) {
        const vaultCreatedEvent = vaultCreatedEvents[i];
        const vaultAddress = vaultCreatedEvent.args.vault;
        console.log(`Current Vault address: ${vaultAddress}`);
        let vaultUser;
        const signers = await ethers.getSigners();
        for (let j in signers) {
            const signer = signers[j];
            const signerAddress = await signer.getAddress();
            if (signerAddress === vaultCreatedEvent.args.user) {
                vaultUser = signer;
            }
        }

        const vaultContract = new ethers.Contract(vaultAddress, vaultAbi, vaultUser);

        let tx = await ERC20.attach(await vaultContract.stake()).connect(vaultUser).approve(vaultAddress, _common_deposit_amount);
        await tx.wait();
        console.log(`Approved amount: ${_common_deposit_amount} of LP token: ${await vaultContract.stake()} to vault: ${vaultAddress}`);

        tx = await CakeLpStakingV1.attach(await vaultContract.strategy()).connect(user1).setPendingRewardsFunctionName("pendingCake");
        await tx.wait();

        tx = await vaultContract.deposit(_common_deposit_amount);
        await tx.wait();
        console.log(`Deposited ${_common_deposit_amount} LPs into vault: ${await vaultContract.name()}`);
    }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
