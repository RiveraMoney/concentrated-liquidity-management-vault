import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";

export default async function transferMeTokens(taskArgs: any, hre: HardhatRuntimeEnvironment) {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [taskArgs.tokenwhale],
  });
  //get all accounts
  const accounts = await hre.ethers.getSigners();
  console.log(accounts.length);
  let whale = await hre.ethers.getSigner(taskArgs.tokenwhale)
  let token = await hre.ethers.getContractAt("IERC20", taskArgs.token)

  console.log(`token balance of whale: ${taskArgs.tokenwhale}`, await token.balanceOf(taskArgs.tokenwhale));

  for (let i = 2; i < accounts.length; i++) {
    let tx = await token.connect(whale).transfer(accounts[i].address, taskArgs.amount);
    await tx.wait();
    console.log(`token balance of user : ${accounts[i].address}`, await token.balanceOf(accounts[i].address));
  }

//   let tx = await token.connect(whale).transfer(taskArgs.account1, taskArgs.amount);
//   await tx.wait();
//   console.log(`token balance of user : ${taskArgs.account1}`, await token.balanceOf(taskArgs.account1));
}