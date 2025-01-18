require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27",

  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },

  networks: {
    sonicTestnet: {
      url: "https://rpc.blaze.soniclabs.com",
      chainId: 57054,
      accounts: [process.env.private_key], 
    },
    kairos: {
      url: "https://public-en-kairos.node.kaia.io",
      chainId: 1001,
      accounts: [process.env.private_key], 
    },
    basesepolia: {
      url: process.env.BASE_SEPOLIA_RPC_URL,
      chainId: 84532, 
      accounts: [process.env.private_key], 
      gasPrice: 1000000000,
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      chainId: 11155111,
      accounts: [process.env.private_key],
    },
    lisksepolia: {
      url: process.env.Lisk_SEPOLIA_RPC_URL,
      chainId: 4202, 
      accounts: [process.env.private_key],
    },
  },

  etherscan: {
    apiKey: {
      basesepolia: process.env.BASESCAN_API_KEY,
      kairos: "unnecessary", 
      sonicTestnet: process.env.SONICBLAST_API_KEY,
      sepolia: process.env.ETHERSCAN_API_KEY,
      lisksepolia: process.env.LISK_API_KEY,
    },
    customChains: [
      {
        network: "sonicTestnet",
        chainId: 57054,
        urls: {
          apiURL: "https://api-testnet.sonicscan.org/api",
          browserURL: "https://testnet.sonicscan.org",
        },
      },
      {
        
       network: "basesepolia",
       chainId: 84532,
       urls: {
        apiURL: "https://api-sepolia.basescan.org/api",
        browserURL: "https://sepolia.basescan.org"
       }
      },
      {
        network: "kairos",
        chainId: 1001,
        urls: {
          apiURL: "https://api-baobab.klaytnscope.com/api",
          browserURL: "https://kairos.kaiascope.com",
        },
      },
      {
        network: "sepolia",
        chainId: 11155111,
        urls: {
          apiURL: "https://api-sepolia.etherscan.io/api",
          browserURL: "https://sepolia.etherscan.io",
        },
      },
      {
        network: "lisksepolia",
        chainId: 4202, 
         urls: {
              apiURL: "https://sepolia-blockscout.lisk.com/api",
              browserURL: "https://sepolia-blockscout.lisk.com"
          }
      },
    ],
  },
  ignition: {
    strategyConfig: {
      create2: {
        // To learn more about salts, see the CreateX documentation
        // bytes32  SALT_AIRDROP = keccak256("SonikDropAirdropFactoryFacet");
        salt: "0xfb4dfcab774cb21c02420d33a6f90c9edcdd51187d92fa7f029d3e26af184b49",
      },
    },
  },
};
