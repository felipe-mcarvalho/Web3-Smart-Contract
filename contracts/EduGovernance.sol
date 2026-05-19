// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
    DAO simplificada.
    O peso do voto considera o saldo atual de tokens EDU no momento da votacao.
    Nao ha snapshot, delegacao ou execucao automatica de propostas.
*/
contract EduGovernance is Ownable {
    struct Proposal {
        string description;
        uint256 deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool finalized;
        bool approved;
    }

    IERC20 public immutable governanceToken;
    uint256 public proposalCount;

    mapping(uint256 => Proposal) private proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(uint256 indexed proposalId, string description, uint256 deadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalFinalized(uint256 indexed proposalId, bool approved, uint256 votesFor, uint256 votesAgainst);

    constructor(address tokenAddress) Ownable(msg.sender) {
        require(tokenAddress != address(0), "Invalid token address.");
        governanceToken = IERC20(tokenAddress);
    }

    function createProposal(string memory description, uint256 durationInSeconds)
        external
        onlyOwner
        returns (uint256)
    {
        require(bytes(description).length > 0, "Description cannot be empty.");
        require(durationInSeconds > 0, "Duration must be greater than zero.");

        proposalCount += 1;
        uint256 proposalId = proposalCount;

        proposals[proposalId] = Proposal({
            description: description,
            deadline: block.timestamp + durationInSeconds,
            votesFor: 0,
            votesAgainst: 0,
            finalized: false,
            approved: false
        });

        emit ProposalCreated(proposalId, description, block.timestamp + durationInSeconds);
        return proposalId;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.deadline > 0, "Proposal does not exist.");
        require(block.timestamp <= proposal.deadline, "Voting period has ended.");
        require(!proposal.finalized, "Proposal already finalized.");
        require(!hasVoted[proposalId][msg.sender], "Address has already voted.");

        uint256 weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power available.");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }

        emit VoteCast(proposalId, msg.sender, support, weight);
    }

    function finalizeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.deadline > 0, "Proposal does not exist.");
        require(block.timestamp > proposal.deadline, "Voting period is still active.");
        require(!proposal.finalized, "Proposal already finalized.");

        proposal.finalized = true;
        proposal.approved = proposal.votesFor > proposal.votesAgainst;

        emit ProposalFinalized(
            proposalId,
            proposal.approved,
            proposal.votesFor,
            proposal.votesAgainst
        );
    }

    function getProposal(uint256 proposalId)
        external
        view
        returns (
            string memory description,
            uint256 deadline,
            uint256 votesFor,
            uint256 votesAgainst,
            bool finalized,
            bool approved
        )
    {
        Proposal memory proposal = proposals[proposalId];
        require(proposal.deadline > 0, "Proposal does not exist.");

        return (
            proposal.description,
            proposal.deadline,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.finalized,
            proposal.approved
        );
    }
}
