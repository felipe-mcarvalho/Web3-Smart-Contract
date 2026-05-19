// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/AggregatorV3Interface.sol";

/*
    Contrato de staking.
    O usuario deposita tokens EDU e acumula recompensa ao longo do tempo.
    Um preco externo ETH/USD, lido por oraculo, pode aplicar um bonus simples.
*/
contract EduStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct StakeInfo {
        uint256 amount;
        uint256 lastUpdateTime;
        uint256 unclaimedRewards;
    }

    IERC20 public immutable stakingToken;
    AggregatorV3Interface public immutable priceFeed;

    uint256 public totalStaked;
    uint256 public totalRewardsPaid;

    // Taxa simplificada: quanto maior o valor, maior a recompensa por segundo.
    uint256 public rewardRatePerSecond = 1e10;

    // Exemplo usando preco ETH/USD com 8 casas, comum em feeds da Chainlink.
    uint256 public bonusPriceThreshold;
    uint256 public oracleBonusPercent = 10;

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardPoolFunded(address indexed from, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event BonusThresholdUpdated(uint256 newThreshold);
    event OracleBonusUpdated(uint256 newBonusPercent);

    constructor(address tokenAddress, address priceFeedAddress, uint256 threshold)
        Ownable(msg.sender)
    {
        require(tokenAddress != address(0), "Invalid token address.");
        require(priceFeedAddress != address(0), "Invalid price feed address.");

        stakingToken = IERC20(tokenAddress);
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        bonusPriceThreshold = threshold;
    }

    function fundRewards(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero.");

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardPoolFunded(msg.sender, amount);
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero.");

        _updateRewards(msg.sender);

        stakes[msg.sender].amount += amount;
        totalStaked += amount;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero.");
        require(stakes[msg.sender].amount >= amount, "Insufficient staked balance.");

        _updateRewards(msg.sender);

        stakes[msg.sender].amount -= amount;
        totalStaked -= amount;

        stakingToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimReward() external nonReentrant {
        _updateRewards(msg.sender);

        uint256 reward = stakes[msg.sender].unclaimedRewards;
        require(reward > 0, "No rewards available.");
        require(availableRewardPool() >= reward, "Insufficient reward pool.");

        stakes[msg.sender].unclaimedRewards = 0;
        totalRewardsPaid += reward;

        stakingToken.safeTransfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function pendingReward(address account) external view returns (uint256) {
        StakeInfo memory info = stakes[account];
        uint256 newReward = _calculateReward(info.amount, info.lastUpdateTime);
        return info.unclaimedRewards + newReward;
    }

    function availableRewardPool() public view returns (uint256) {
        uint256 contractBalance = stakingToken.balanceOf(address(this));

        if (contractBalance <= totalStaked) {
            return 0;
        }

        return contractBalance - totalStaked;
    }

    function getLatestEthPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        require(answer > 0, "Invalid oracle price.");
        return uint256(answer);
    }

    function getOracleDecimals() external view returns (uint8) {
        return priceFeed.decimals();
    }

    function setRewardRatePerSecond(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Rate must be greater than zero.");
        rewardRatePerSecond = newRate;
        emit RewardRateUpdated(newRate);
    }

    function setBonusPriceThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Threshold must be greater than zero.");
        bonusPriceThreshold = newThreshold;
        emit BonusThresholdUpdated(newThreshold);
    }

    function setOracleBonusPercent(uint256 newPercent) external onlyOwner {
        require(newPercent <= 100, "Bonus percent too high.");
        oracleBonusPercent = newPercent;
        emit OracleBonusUpdated(newPercent);
    }

    function _updateRewards(address account) internal {
        StakeInfo storage info = stakes[account];

        if (info.amount > 0 && info.lastUpdateTime > 0) {
            uint256 newReward = _calculateReward(info.amount, info.lastUpdateTime);
            info.unclaimedRewards += newReward;
        }

        info.lastUpdateTime = block.timestamp;
    }

    function _calculateReward(uint256 stakedAmount, uint256 lastUpdateTime) internal view returns (uint256) {
        if (stakedAmount == 0 || lastUpdateTime == 0) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp - lastUpdateTime;
        uint256 baseReward = (stakedAmount * rewardRatePerSecond * elapsedTime) / 1e18;

        return _applyOracleBonus(baseReward);
    }

    function _applyOracleBonus(uint256 reward) internal view returns (uint256) {
        if (reward == 0) {
            return 0;
        }

        uint256 latestPrice = getLatestEthPrice();

        if (latestPrice >= bonusPriceThreshold) {
            uint256 bonus = (reward * oracleBonusPercent) / 100;
            return reward + bonus;
        }

        return reward;
    }
}
