const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EduStake DAO MVP", function () {
  async function deployFixture() {
    const [owner, alice] = await ethers.getSigners();

    const MockV3Aggregator = await ethers.getContractFactory("MockV3Aggregator");
    const mockOracle = await MockV3Aggregator.deploy(8, 300000000000n);
    await mockOracle.waitForDeployment();

    const EduToken = await ethers.getContractFactory("EduToken");
    const token = await EduToken.deploy(ethers.parseUnits("1000000", 18));
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
      await mockOracle.getAddress(),
      300000000000n
    );
    await staking.waitForDeployment();

    await (await token.transfer(alice.address, ethers.parseUnits("1000", 18))).wait();
    await (await token.approve(await staking.getAddress(), ethers.parseUnits("50000", 18))).wait();
    await (await staking.fundRewards(ethers.parseUnits("50000", 18))).wait();

    return { owner, alice, token, nft, governance, staking, mockOracle };
  }

  it("stakes tokens and claims rewards", async function () {
    const { alice, token, staking } = await deployFixture();
    const stakeAmount = ethers.parseUnits("200", 18);

    await (await token.connect(alice).approve(await staking.getAddress(), stakeAmount)).wait();
    await (await staking.connect(alice).stake(stakeAmount)).wait();

    await ethers.provider.send("evm_increaseTime", [3600]);
    await ethers.provider.send("evm_mine", []);

    const pending = await staking.pendingReward(alice.address);
    expect(pending).to.be.greaterThan(0);

    await (await staking.connect(alice).claimReward()).wait();

    const info = await staking.stakes(alice.address);
    expect(info.unclaimedRewards).to.equal(0);
  });

  it("mints a certificate NFT", async function () {
    const { alice, nft } = await deployFixture();

    await (await nft.mintCertificate(alice.address, "ipfs://certificado-exemplo")).wait();

    expect(await nft.ownerOf(1)).to.equal(alice.address);
  });

  it("creates and finalizes a governance proposal", async function () {
    const { alice, token, governance } = await deployFixture();

    await (await governance.createProposal("Criar nova campanha educacional", 3600)).wait();
    await (await governance.connect(alice).vote(1, true)).wait();

    await ethers.provider.send("evm_increaseTime", [3601]);
    await ethers.provider.send("evm_mine", []);

    await (await governance.finalizeProposal(1)).wait();

    const proposal = await governance.getProposal(1);
    expect(proposal[5]).to.equal(true);
    expect(proposal[2]).to.equal(ethers.parseUnits("1000", 18));
  });
});
