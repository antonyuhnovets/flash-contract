require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.5.0",
        settings: {},
      },
      {
        version: "0.7.6",
        settings: {},
      },
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
            details: {
              inliner: true,
              cse: true, 
              orderLiterals: true
            }
          },
          evmVersion: "london", // Version of the EVM to compile for. Affects type checking and code generation. Can be homestead, tangerineWhistle, spuriousDragon, byzantium, constantinople or petersburg
            // Metadata settings (optional)
            metadata: {
              // Use only literal content and not URLs (false by default)
              useLiteralContent: true,
              bytecodeHash: "ipfs"
            },
          debug: {
            // How to treat revert (and require) reason strings. Settings are
            // "default", "strip", "debug" and "verboseDebug".
            // "default" does not inject compiler-generated revert strings and keeps user-supplied ones.
            // "strip" removes all revert strings (if possible, i.e. if literals are used) keeping side-effects
            // "debug" injects strings for compiler-generated internal reverts, implemented for ABI encoders V1 and V2 for now.
            // "verboseDebug" even appends further information to user-supplied revert strings (not yet implemented)
            revertStrings: "debug",
            // Optional: How much extra debug information to include in comments in the produced EVM
            // assembly and Yul code. Available components are:
            // - `location`: Annotations of the form `@src <index>:<start>:<end>` indicating the
            //    location of the corresponding element in the original Solidity file, where:
            //     - `<index>` is the file index matching the `@use-src` annotation,
            //     - `<start>` is the index of the first byte at that location,
            //     - `<end>` is the index of the first byte after that location.
            // - `snippet`: A single-line code snippet from the location indicated by `@src`.
            //     The snippet is quoted and follows the corresponding `@src` annotation.
            // - `*`: Wildcard value that can be used to request everything.
            debugInfo: ["location", "snippet"]
            },
          outputSelection: {
            "*": {
              "*": [
                "evm.bytecode.sourceMap",
                "evm.gasEstimates",
                "evm.methodIdentifiers",
                "evm.bytecode",
                "evm.deployedBytecode",
                "devdoc",
                "userdoc",
                "metadata",
                "abi"
              ],
              "": [
                "ast"
              ]
            }
          },
          libraries: {}
        },
      },
    ],
  },
  networks: {
    mumbai: {
      url: process.env.MUMBAI_ENDPOINT,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY],
      gasLimit: 300000000,
    },
    goerli: {
      url: process.env.ETH_GOERLI_ENDPOINT,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY],
      gasLimit: 300000000,
    },
    goerliArb: {
      url: process.env.ARB_GOERLI_ENDPOINT,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY],
      gasLimit: 300000000,
    },
    sepolita: {
      url: process.env.ETH_SEPOLITA_ENDPOINT,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY],
      gasLimit: 300000000,
    },
  },
  etherscan: {
    apiKey: {
      arbitrumGoerli: process.env.ARB_GOERLI_KEY,
      polygonMumbai: process.env.MUMBAI_KEY,
      goerli: process.env.ETH_GOERLI_KEY,
    }
  }
};
