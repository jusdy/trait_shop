const { network } = require('hardhat')

async function main() {
  const [deployer] = await ethers.getSigners();
  const ApesTraits = "0x5e2f3b76cD5df52BBf4bcB9f50003bf769742dc9";
  console.log("network name -----_>" + network.name);
  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const TraitShop = await ethers.getContractFactory("TraitShop");
  const contract = await TraitShop.deploy(ApesTraits, 10);

  console.log("TraitShop address:", contract.address);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });