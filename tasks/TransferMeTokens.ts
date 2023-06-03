import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";

export default async function transferMeTokens(taskArgs: any, hre: HardhatRuntimeEnvironment) {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [taskArgs.tokenwhale],
  });
  // //transfer some eth callefr
  // // Get the accounts
  // const [account1] = await hre.ethers.getSigners();

  // // Transfer ETH to the desired account
  
  // await account1.sendTransaction({
  //   to:taskArgs.tokenwhale,
  //   value: hre.ethers.utils.parseEther('1'),
  // });

  let whale = await hre.ethers.getSigner(taskArgs.tokenwhale)
  let token = await hre.ethers.getContractAt("IERC20", taskArgs.token)

  console.log(`token balance of whale: ${taskArgs.tokenwhale}`, await token.balanceOf(taskArgs.tokenwhale));

  let tx = await token.connect(whale).transfer(taskArgs.account1, taskArgs.amount);
  await tx.wait();
  console.log(`token balance of user : ${taskArgs.account1}`, await token.balanceOf(taskArgs.account1));

  let tx1 = await token.connect(whale).transfer(taskArgs.account2, taskArgs.amount);
  await tx1.wait();
  console.log(`token balance of user : ${taskArgs.account2}`, await token.balanceOf(taskArgs.account2));

}