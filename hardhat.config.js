require('dotenv').config();
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
// The next line is part of the sample project, you don't need it in your
// project. It imports a Hardhat task definition, that can be used for
// testing the frontend.
//require("./tasks/faucet");
const { API_KEY } = process.env;

module.exports = {
  solidity: "0.8.19",
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    goerli: {
      url: "https://goerli.infura.io/v3/",
    }
  },
  etherscan: {
    apiKey: {
      rinkeby: API_KEY
    }
  }
};
