import { HardhatRuntimeEnvironment } from "hardhat/types/runtime";

export default async function transferMeTokens(taskArgs: any, hre: HardhatRuntimeEnvironment) {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [taskArgs.tokenwhale],
  });

  let whale = await hre.ethers.getSigner(taskArgs.tokenwhale)
  let token = await hre.ethers.getContractAt("IERC20", taskArgs.token)

  const [user1, user2] = await (hre.ethers as any).getSigners();

  console.log(`token balance of whale: ${taskArgs.tokenwhale}`, await token.balanceOf(taskArgs.tokenwhale));

  let tx = await token.connect(whale).transfer(await user1.getAddress(), taskArgs.amount);
  await tx.wait();
  console.log(`token balance of user 1: ${await user1.getAddress()}`, await token.balanceOf(await user1.getAddress()));

  tx = await token.connect(whale).transfer(await user2.getAddress(), taskArgs.amount);
  await tx.wait();
  console.log(`token balance of user 2: ${await user2.getAddress()}`, await token.balanceOf(await user2.getAddress()));

}