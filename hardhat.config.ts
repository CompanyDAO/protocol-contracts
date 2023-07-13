import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "hardhat-spdx-license-identifier";
import "solidity-coverage";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-deploy";
import "hardhat-dependency-compiler";
import "hardhat-docgen";
import "hardhat-abi-exporter";
import "hardhat-contract-sizer";
import "solidity-docgen";
import "./tasks";
import "./tasks/doc.js";

dotenv.config();

const networkConfig = (url: string | null | undefined) => ({
  url: url || "",
  accounts:
    process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
});

const onlyContracts = () => ({
  only: [
    ":Registry$",
    ":Service$",
    ":Pool$",
    ":TGE$",
    ":Token$",
    ":TokenERC1155$",
    ":Vesting$",
    ":CustomProposal$",
    ":Invoice$",
    ":TGEFactory$",
    ":TokenFactory$"
  ]
});

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
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
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
      /*forking: {
                url: process.env.FORKING_RPC_URL!,
                blockNumber: 15050841,
            },*/
    },
    mainnet: { ...networkConfig(process.env.MAINNET_RPC_URL!) },
    goerli: { ...networkConfig(process.env.GOERLI_RPC_URL!) },
    polygon: { ...networkConfig(process.env.POLYGON_RPC_URL!) },
    mumbai: {
      ...networkConfig(process.env.MUMBAI_RPC_URL!)
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  docgen: {
    path: './docs',
    clear: true,
    ...onlyContracts()
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    //runOnCompile: true,
  },
  verify: {
    etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY,
    },
  },
  dependencyCompiler: {
    paths: ["@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol"],
  },
  abiExporter: {
    path: "./abi",
    runOnCompile: true,
    format: "json",
    clear: true,
    flat: true,
    spacing: 4,
    ...onlyContracts()
  },
};

export default config;
