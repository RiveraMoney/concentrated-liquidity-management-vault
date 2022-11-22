import { ethers } from "hardhat";
var fs = require('fs');

const _chef = "0xa5f8C5Dbd5F286960b9d90548680aE5ebFf07652";   //Address of the pancake master chef v2 contract on BSC mainnet
const _router = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; //Address of Pancake Swap router
const _pancakeFactory = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73";
const stratUpdateDelay = 21600;

//To keep the contract deployment address same always restart the blockchain before deploying, as the deployed contract address depends on the nonce
async function main() {
    const PancakeVaultFactoryV1 = await ethers.getContractFactory("PancakeVaultFactoryV1");
    // console.log(PancakeVaultFactoryV1);
    const pancakeVaultFactoryV1 = await PancakeVaultFactoryV1.deploy(_chef, _router, _pancakeFactory);

    await pancakeVaultFactoryV1.deployed();

    var pancakeVaultFactoryV1Address = {
        contractAddress: pancakeVaultFactoryV1.address
    };
    var json = JSON.stringify(pancakeVaultFactoryV1Address);
    const callback = () => {

    }

    fs.writeFile('contractAddress.json', json, 'utf8', callback);

    console.log("Rivera Factory contract deployed to:", pancakeVaultFactoryV1.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
