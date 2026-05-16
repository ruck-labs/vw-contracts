import hardhatToolboxViemPlugin from "@nomicfoundation/hardhat-toolbox-viem";
import { configVariable, defineConfig } from "hardhat/config";

export default defineConfig({
  plugins: [hardhatToolboxViemPlugin],
  // Kaia Kairos (1001) — compiler-api-v2 endpoint (no API key required)
  // https://docs.kaiascan.io/smart-contract-verification/hardhat-verify
  chainDescriptors: {
    1001: {
      name: "Kaia Kairos",
      chainType: "l1",
      blockExplorers: {
        etherscan: {
          name: "Kaiascan",
          url: "https://kairos.kaiascan.io",
          apiUrl: "https://compiler-api-v2.kaiascan.io/kairos/hardhat-verify",
        },
      },
    },
  },
  verify: {
    etherscan: {
      apiKey: "unnecessary",
    },
  },
  solidity: {
    profiles: {
      default: {
        version: "0.8.28",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      production: {
        version: "0.8.28",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
  },
  networks: {
    hardhatMainnet: {
      type: "edr-simulated",
      chainType: "l1",
    },
    hardhatOp: {
      type: "edr-simulated",
      chainType: "op",
    },
    kairos: {
      type: "http",
      chainType: "l1",
      url: configVariable("KAIA_KAIROS_RPC_URL"),
      accounts: [configVariable("DEPLOYER_PRIVATE_KEY")],
    },
  },
  // Required for `ignition deploy --strategy create2` (CreateX). See:
  // https://hardhat.org/ignition/docs/guides/create2
  ignition: {
    strategyConfig: {
      create2: {
        salt: "0x0000000000000000000000000000000000000000000000000000000000000000",
      },
    },
  },
});
