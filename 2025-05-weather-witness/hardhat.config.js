require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require("hardhat-deploy");
require("dotenv").config();


const AVAX_FUJI_RPC_URL = process.env.AVAX_FUJI_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const AVAX_API_KEY = process.env.AVAX_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.29",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
      evmVersion: "shanghai",
    },
  },

  defaultNetwork: "hardhat",

  networks: {
    hardhat: {},

    avalancheFuji: {
      url: AVAX_FUJI_RPC_URL,
      chainId: 43113,
      accounts: [PRIVATE_KEY],
      blockConfirmations: 3
    }
  },

  namedAccounts: {
    deployer: {
      default: 0
    }
  },

  etherscan: {
    apiKey: AVAX_API_KEY
  },

  mocha: {
    timeout: 1000000
  }
};