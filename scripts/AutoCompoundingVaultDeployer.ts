import { ethers } from "hardhat";
var fs = require('fs');

import { default as vaultArtifact } from "../artifacts/src/vaults/RiveraAutoCompoundingVaultV1.sol/RiveraAutoCompoundingVaultV1.json";
const vaultAbi = vaultArtifact.abi;

const _cake = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82";   //Address of the cake token on BSC mainnet
const _wbnb = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"; //Address of WBNB
const _busd = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
const _usdt = "0x55d398326f99059fF775485246999027B3197955";
const stratUpdateDelay = 21600;

//To keep the contract deployment address same always restart the blockchain before deploying, as the deployed contract address depends on the nonce
async function main() {

    const jsonString = fs.readFileSync('contractAddress.json');
    const pancakeVaultFactoryV1Address = JSON.parse(jsonString);

    const PancakeVaultFactoryV1 = await ethers.getContractFactory("PancakeVaultFactoryV1");
    const pancakeVaultFactoryV1 = await PancakeVaultFactoryV1.attach(pancakeVaultFactoryV1Address.contractAddress);

    const [user1, user2] = await ethers.getSigners();

    let tx = await pancakeVaultFactoryV1.connect(user1).createVault({
        poolId: 2,
        approvalDelay: stratUpdateDelay,
        rewardToLp0Route: [_cake],
        rewardToLp1Route: [_cake, _wbnb],
        tokenName: "USER1-CAKE-BNB-LP-VAULT",
        tokenSymbol: "USER1-CAKE-BNB-LP-VAULT"
    });
    await tx.wait();
    console.log(`USER1-CAKE-BNB-LP-VAULT created!`);

    tx = await pancakeVaultFactoryV1.connect(user1).createVault({
        poolId: 39,
        approvalDelay: stratUpdateDelay,
        rewardToLp0Route: [_cake],
        rewardToLp1Route: [_cake, _wbnb, _busd],
        tokenName: "USER1-CAKE-BUSD-LP-VAULT",
        tokenSymbol: "USER1-CAKE-BUSD-LP-VAULT"
    });
    await tx.wait();
    console.log(`USER1-CAKE-BUSD-LP-VAULT created!`);

    tx = await pancakeVaultFactoryV1.connect(user2).createVault({
        poolId: 47,
        approvalDelay: stratUpdateDelay,
        rewardToLp0Route: [_cake],
        rewardToLp1Route: [_cake, _wbnb, _usdt],
        tokenName: "USER2-CAKE-USDT-LP-VAULT",
        tokenSymbol: "USER2-CAKE-USDT-LP-VAULT"
    });
    await tx.wait();
    console.log(`USER2-CAKE-USDT-LP-VAULT created!`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
