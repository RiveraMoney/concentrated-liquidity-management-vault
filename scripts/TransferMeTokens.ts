import { ethers, network } from "hardhat";

const TOKEN: string = "0x804678fa97d91B974ec2af3c843270886528a9E6"; // Address of the token you want
const TOKEN_WHALE: string = "0x1cbD4cAb7006EAE6c7e3C65eDcFA9411dC3c8c30"; // Address of the account which has a lot of the tokens you want
const amount = "100000000000000000000";

async function main() {
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [TOKEN_WHALE],
  });

  let whale = await ethers.getSigner(TOKEN_WHALE)
  let token = await ethers.getContractAt("IERC20", TOKEN)

  const [user1, user2] = await (ethers as any).getSigners();

  console.log(`token balance of whale: ${TOKEN_WHALE}`, await token.balanceOf(TOKEN_WHALE));

  let tx = await token.connect(whale).transfer(await user1.getAddress(), amount);
  await tx.wait();
  console.log(`token balance of user 1: ${await user1.getAddress()}`, await token.balanceOf(await user1.getAddress()));

  tx = await token.connect(whale).transfer(await user2.getAddress(), amount);
  await tx.wait();
  console.log(`token balance of user 2: ${await user2.getAddress()}`, await token.balanceOf(await user2.getAddress()));

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
