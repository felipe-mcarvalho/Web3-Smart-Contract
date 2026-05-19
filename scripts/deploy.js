const fs = require("fs");
const path = require("path");
const hre = require("hardhat");

function toUnits(value) {
  return hre.ethers.parseUnits(value, 18);
}

function writeDeployment(networkName, data) {
  const deploymentsDir = path.join(__dirname, "..", "deployments");

  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }

  fs.writeFileSync(
    path.join(deploymentsDir, `${networkName}.json`),
    JSON.stringify(data, null, 2)
  );

  fs.writeFileSync(
    path.join(deploymentsDir, "latest.json"),
    JSON.stringify(data, null, 2)
  );
}

async function main() {
  const { ethers, network } = hre;
  const [deployer] = await ethers.getSigners();

  const initialSupply = process.env.INITIAL_SUPPLY || "1000000";
  const rewardPoolAmount = process.env.REWARD_POOL_AMOUNT || "50000";
  const bonusThreshold = process.env.BONUS_PRICE_THRESHOLD || "300000000000";
  const mockOraclePrice = process.env.MOCK_ORACLE_PRICE || "300000000000";

  console.log(`Deploy network: ${network.name}`);
  console.log(`Deployer: ${deployer.address}`);

  let priceFeedAddress = process.env.PRICE_FEED_ADDRESS;
  let mockOracleAddress = null;

  if (network.name === "hardhat" || network.name === "localhost") {
    const MockV3Aggregator = await ethers.getContractFactory("MockV3Aggregator");
    const mockOracle = await MockV3Aggregator.deploy(8, mockOraclePrice);
    await mockOracle.waitForDeployment();
    mockOracleAddress = await mockOracle.getAddress();
    priceFeedAddress = mockOracleAddress;
  }

  if (!priceFeedAddress) {
    throw new Error("PRICE_FEED_ADDRESS is required for this network.");
  }

  const EduToken = await ethers.getContractFactory("EduToken");
  const token = await EduToken.deploy(toUnits(initialSupply));
  await token.waitForDeployment();

  const CertificadoNFT = await ethers.getContractFactory("CertificadoNFT");
  const nft = await CertificadoNFT.deploy();
  await nft.waitForDeployment();

  const EduGovernance = await ethers.getContractFactory("EduGovernance");
  const governance = await EduGovernance.deploy(await token.getAddress());
  await governance.waitForDeployment();

  const EduStaking = await ethers.getContractFactory("EduStaking");
  const staking = await EduStaking.deploy(
    await token.getAddress(),
    priceFeedAddress,
    bonusThreshold
  );
  await staking.waitForDeployment();

  const stakingAddress = await staking.getAddress();
  await (await token.approve(stakingAddress, toUnits(rewardPoolAmount))).wait();
  await (await staking.fundRewards(toUnits(rewardPoolAmount))).wait();

  const deploymentData = {
    network: network.name,
    deployer: deployer.address,
    mockOracle: mockOracleAddress,
    priceFeedAddress,
    token: await token.getAddress(),
    nft: await nft.getAddress(),
    staking: stakingAddress,
    governance: await governance.getAddress()
  };

  writeDeployment(network.name, deploymentData);

  console.log("Deployment complete:");
  console.log(deploymentData);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
