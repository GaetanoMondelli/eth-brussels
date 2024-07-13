import * as dotenv from "dotenv";
dotenv.config();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "@nomicfoundation/hardhat-verify";
import "hardhat-deploy";
import "hardhat-deploy-ethers";

// If not set, it uses ours Alchemy's default API key.
// You can get your own at https://dashboard.alchemyapi.io
const providerApiKey = process.env.ALCHEMY_API_KEY || "oKxs-03sij-U_N0iOlrSsZFr29-IqbuF";
// If not set, it uses the hardhat account 0 private key.
const deployerPrivateKey =
  process.env.DEPLOYER_PRIVATE_KEY ?? "1294695293f333466d699cca83fce35cf2c3dd960fd35a93d44ae548835c9b32";
// If not set, it uses ours Etherscan default API key.
const etherscanApiKey = process.env.ETHERSCAN_API_KEY || "85UU6IZBVUHJWHITKYEHZ3MRRSJS11UWT6";

const FLARE_RPC_API_KEY = "123456";
const FLARESCAN_API_KEY = "irrelevant";
const FLARE_EXPLORER_API_KEY = "TODO";
const config: HardhatUserConfig = {
  solidity: {
    // version: "0.8.17",
    // settings: {
    //   optimizer: {
    //     enabled: true,
    //     // https://docs.soliditylang.org/en/latest/using-the-compiler.html#optimizer-options
    //     runs: 200,
    //   },
    // },
    compilers: [
      // {
      //   version: "0.8.24",
      //   settings: {
      //     optimizer: {
      //       enabled: true,
      //       runs: 200,
      //     },
      //   },
      // },
      {
        version: "0.8.22",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  defaultNetwork: "localhost",
  namedAccounts: {
    deployer: {
      // By default, it will take the first Hardhat account as the deployer
      default: 0,
    },
  },
  networks: {
    // View the networks that are pre-configured.
    // If the network you are looking for is not here you can add new network settings
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${providerApiKey}`,
        enabled: process.env.MAINNET_FORKING_ENABLED === "true",
      },
    },
    coston: {
      url:
        "https://coston-api.flare.network/ext/bc/C/rpc" + (FLARE_RPC_API_KEY ? `?x-apikey=${FLARE_RPC_API_KEY}` : ""),
      accounts: [deployerPrivateKey],
      chainId: 16,
    },
    coston2: {
      url: "https://coston2-api.flare.network/ext/C/rpc" + (FLARE_RPC_API_KEY ? `?x-apikey=${FLARE_RPC_API_KEY}` : ""),
      accounts: [deployerPrivateKey],
      chainId: 114,
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    sepolia: {
      // url: `https://eth-sepolia.g.alchemy.com/v2/${providerApiKey}`,
      url: "https://orbital-capable-season.ethereum-sepolia.quiknode.pro/8a961b76e01b85d94eb0568af4d471c8f46ea07c/",
      // url: "https://eth-sepolia.g.alchemy.com/v2/RFiBHY2-HWqMY3wHC_lMpOKdJfji5EgY",
      accounts: [deployerPrivateKey],
      chainId: 11155111,
    },
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    arbitrum: {
      url: `https://arb-mainnet.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    arbitrumSepolia: {
      url: `https://arb-sepolia.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    optimism: {
      url: `https://opt-mainnet.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    optimismSepolia: {
      url: `https://opt-sepolia.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    polygon: {
      url: `https://polygon-mainnet.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    polygonMumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    polygonZkEvm: {
      url: `https://polygonzkevm-mainnet.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    polygonZkEvmTestnet: {
      url: `https://polygonzkevm-testnet.g.alchemy.com/v2/${providerApiKey}`,
      accounts: [deployerPrivateKey],
    },
    gnosis: {
      url: "https://rpc.gnosischain.com",
      accounts: [deployerPrivateKey],
    },
    chiado: {
      url: "https://rpc.chiadochain.net",
      accounts: [deployerPrivateKey],
    },
    base: {
      url: "https://mainnet.base.org",
      accounts: [deployerPrivateKey],
    },
    baseGoerli: {
      url: "https://goerli.base.org",
      accounts: [deployerPrivateKey],
    },
    baseSepolia: {
      url: "https://sepolia.base.org",
      accounts: [deployerPrivateKey],
    },
    scrollSepolia: {
      url: "https://sepolia-rpc.scroll.io",
      accounts: [deployerPrivateKey],
    },
    scroll: {
      url: "https://rpc.scroll.io",
      accounts: [deployerPrivateKey],
    },
    pgn: {
      url: "https://rpc.publicgoods.network",
      accounts: [deployerPrivateKey],
    },
    pgnTestnet: {
      url: "https://sepolia.publicgoods.network",
      accounts: [deployerPrivateKey],
    },
  },
  // configuration for harhdat-verify plugin
  etherscan: {
    // apiKey: `${etherscanApiKey}`,
    apiKey: {
      goerli: `${etherscanApiKey}`,
      coston: `${FLARESCAN_API_KEY}`,
      coston2: `${FLARESCAN_API_KEY}`,
      songbird: `${FLARESCAN_API_KEY}`,
      flare: `${FLARESCAN_API_KEY}`,
      sepolia: `${etherscanApiKey}`,
    },
    customChains: [
      {
        network: "coston",
        chainId: 16,
        urls: {
          // faucet: https://faucet.towolabs.com/
          apiURL:
            "https://coston-explorer.flare.network/api" +
            (FLARE_EXPLORER_API_KEY ? `?x-apikey=${FLARE_EXPLORER_API_KEY}` : ""), // Must not have / endpoint
          browserURL: "https://coston-explorer.flare.network",
        },
      },
      {
        network: "coston2",
        chainId: 114,
        urls: {
          // faucet: https://coston2-faucet.towolabs.com/
          apiURL:
            "https://coston2-explorer.flare.network/api" +
            (FLARE_EXPLORER_API_KEY ? `?x-apikey=${FLARE_EXPLORER_API_KEY}` : ""), // Must not have / endpoint
          browserURL: "https://coston2-explorer.flare.network",
        },
      },
      {
        network: "songbird",
        chainId: 19,
        urls: {
          apiURL:
            "https://songbird-explorer.flare.network/api" +
            (FLARE_EXPLORER_API_KEY ? `?x-apikey=${FLARE_EXPLORER_API_KEY}` : ""), // Must not have / endpoint
          browserURL: "https://songbird-explorer.flare.network/",
        },
      },
      {
        network: "flare",
        chainId: 14,
        urls: {
          apiURL:
            "https://flare-explorer.flare.network/api" +
            (FLARE_EXPLORER_API_KEY ? `?x-apikey=${FLARE_EXPLORER_API_KEY}` : ""), // Must not have / endpoint
          browserURL: "https://flare-explorer.flare.network/",
        },
      },
    ],
  },
  // configuration for etherscan-verify from hardhat-deploy plugin
  verify: {
    etherscan: {
      apiKey: `${etherscanApiKey}`,
    },
  },
  sourcify: {
    enabled: false,
  },
};

export default config;
