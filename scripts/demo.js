const fs = require("fs");
const path = require("path");
const hre = require("hardhat");

function loadDeployment(networkName) {
  const filePath = path.join(__dirname, "..", "deployments", `${networkName}.json`);

  if (!fs.existsSync(filePath)) {
    throw new Error(`Deployment file not found for network ${networkName}.`);
  }

  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

async function moveTime(seconds) {
  const { network } = hre;

  if (network.name === "hardhat" || network.name === "localhost") {
    await network.provider.send("evm_increaseTime", [seconds]);
    await network.provider.send("evm_mine");
    return true;
  }

  return false;
}

async function main() {
  const { ethers, network } = hre;
  const signers = await ethers.getSigners();
  const admin = signers[0];
  const alice = signers[1] || admin;
  const deployment = loadDeployment(network.name);

  const token = await ethers.getContractAt("EduToken", deployment.token);
  const nft = await ethers.getContractAt("CertificadoNFT", deployment.nft);
  const staking = await ethers.getContractAt("EduStaking", deployment.staking);
  const governance = await ethers.getContractAt("EduGovernance", deployment.governance);

  const transferAmount = ethers.parseUnits("1000", 18);
  const stakeAmount = ethers.parseUnits("300", 18);
  const tokenUri = process.env.DEMO_TOKEN_URI || "ipfs://exemplo-certificado";

  console.log(`Running demo on ${network.name}`);
  console.log(`Admin: ${admin.address}`);
  console.log(`Demo user: ${alice.address}`);

  if (alice.address !== admin.address) {
    await (await token.transfer(alice.address, transferAmount)).wait();
    console.log("Tokens transferred to demo user.");
  } else {
    console.log("Using the admin account as demo user on this network.");
  }

  await (await nft.mintCertificate(alice.address, tokenUri)).wait();
  console.log("NFT minted for demo user.");

  await (await token.connect(alice).approve(await staking.getAddress(), stakeAmount)).wait();
  await (await staking.connect(alice).stake(stakeAmount)).wait();
  console.log("Demo user staked tokens.");

  const usedTimeTravel = await moveTime(3600);

  if (usedTimeTravel) {
    await (await staking.connect(alice).claimReward()).wait();
    console.log("Demo user claimed staking reward.");
  } else {
    console.log("Reward claim skipped because the current network does not support local time travel.");
  }

  await (await governance.createProposal("Distribuir novos certificados para a turma", 3600)).wait();
  console.log("Proposal created.");

  await (await governance.connect(alice).vote(1, true)).wait();
  console.log("Demo user voted in the DAO.");

  if (usedTimeTravel) {
    await moveTime(3601);
    await (await governance.finalizeProposal(1)).wait();
    console.log("Proposal finalized.");
  } else {
    console.log("Finalize skipped. On testnet, wait for the voting period to end before finalizing.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
