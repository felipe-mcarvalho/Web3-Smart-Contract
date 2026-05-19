// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    Mock de oraculo para rede local e testes.
    Ele simula o comportamento basico do price feed da Chainlink.
*/
contract MockV3Aggregator {
    uint8 public immutable decimals;
    int256 private currentAnswer;

    constructor(uint8 feedDecimals, int256 initialAnswer) {
        decimals = feedDecimals;
        currentAnswer = initialAnswer;
    }

    function updateAnswer(int256 newAnswer) external {
        currentAnswer = newAnswer;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, currentAnswer, block.timestamp, block.timestamp, 1);
    }
}
