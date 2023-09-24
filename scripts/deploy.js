require('dotenv').config();
const hre = require("hardhat");

async function main() {
  console.log("deploying...");
  const Contract = await hre.ethers.getContractFactory(process.env.CONTRACT_NAME);
  const contract = await Contract.deploy(
    process.env.CONTRACT_INPUT
  );
  
  await contract.deployed();

  console.log("Contract deployed: ", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
