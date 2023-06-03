import fs from "fs";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-preprocessor";
import { HardhatUserConfig, task } from "hardhat/config";
import * as dotenv from "dotenv";
dotenv.config();

const ADMIN_ACCOUNT = process.env.ADMIN_ACCOUNT;
const MAIN_NET_TRANSACTION_ACCOUNT = process.env.MAIN_NET_TRANSACTION_ACCOUNT;
const TEST_ACCOUNT1 = process.env.TEST_ACCOUNT1;
const TEST_ACCOUNT2 = process.env.TEST_ACCOUNT2;
const BSC_SCAN_API_KEY = process.env.BSC_SCAN_API_KEY;

if (!ADMIN_ACCOUNT || !TEST_ACCOUNT1 || !TEST_ACCOUNT2 || !BSC_SCAN_API_KEY || !MAIN_NET_TRANSACTION_ACCOUNT) {
  throw new Error("ADMIN_ACCOUNT, TEST_ACCOUNT1, MAIN_NET_TRANSACTION_ACCOUNT and BSC_SCAN_API_KEY must be set in .env file.");
}

import example from "./tasks/example";
import transferMeTokens from "./tasks/TransferMeTokens";

function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean)
    .map((line) => line.trim().split("="));
}

task("example", "Example task").setAction(example);
task("TransferMeTokens", "Task to transfer tokens from a whale to you").addParam("tokenwhale", "Whale who has the token")
  .addParam("token", "Address of the tokens you want").addParam("amount", "Amount of tokens you want (In full 18 decimals format)")
  .addParam("account1", "Your account address").setAction(transferMeTokens)
  .addParam("account2", "Your account address").setAction(transferMeTokens)
  .setAction(transferMeTokens);

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
    },
  },
  defaultNetwork: "localBscFork",
  networks: {
    hardhat: {
      chainId: 56,
      accounts: [
        {
          privateKey: `0x${ADMIN_ACCOUNT}`,
          balance: "10000000000000000000000"
        },
        {
          privateKey: `0x${TEST_ACCOUNT1}`,
          balance: "10000000000000000000000"
        },
        {
          privateKey: `0x${TEST_ACCOUNT2}`,
          balance: "10000000000000000000000"
        }
      ]
    },
    bscTest: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: 97,
      accounts: [MAIN_NET_TRANSACTION_ACCOUNT, TEST_ACCOUNT1, TEST_ACCOUNT2]
    },
    bsc: {
      url: "https://bsc-dataseed1.binance.org",
      chainId: 56,
      accounts: [MAIN_NET_TRANSACTION_ACCOUNT, TEST_ACCOUNT1, TEST_ACCOUNT2]
    },
    localBscFork: {
      url: "http://127.0.0.1:8545/",
      chainId: 56,
      timeout: 100_000,
      // accounts: [ADMIN_ACCOUNT, TEST_ACCOUNT1, TEST_ACCOUNT2]          //Impersonating another user's private key on local blockchain works only when this is commented out
    },
  },
  etherscan: {
    apiKey: BSC_SCAN_API_KEY
  },
  paths: {
    sources: "./src", // Use ./src rather than ./contracts as Hardhat expects
    cache: "./cache_hardhat", // Use a different cache for Hardhat than Foundry
  },
  // This fully resolves paths for imports in the ./lib directory for Hardhat
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
};

export default config;
