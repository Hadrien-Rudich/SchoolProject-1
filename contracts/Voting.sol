//SPDX-License-Identifier: MIT

// Le smart contract doit utiliser la dernière version du compilateur
pragma solidity 0.8.22;

// Le smart contract doit utiliser la librairie `Ownable` d'OpenZeppelin
import "@openzeppelin/contracts/access/Ownable.sol";

// Le smart contract doit être nommé `Voting`
contract Voting is Ownable {
    // Le smart contract doit définir un uint représentant la proposition gagnante
    uint public winningProposalId;

    // Le smart contract doit définir les structures de données suivantes :
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    Proposal[] public proposals;
    mapping(address => bool) voters;

    modifier onlyVoter() {
        require(voters[msg.sender], "Restricted to authorized voters");
        _;
    }

    // Votre smart contract doit définir une énumération qui gère les différents états d’un vote
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    // Votre smart contract doit définir les événements suivants :
    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    // L'administrateur déploie le smart contract

    constructor() Ownable(msg.sender) {}

    // function getVoters() {}

    // function getOneProposal(proposalId) private returns (proposal) {}

    // function addVoter() onlyOwner {}

    // function addProposal(proposal) onlyVoter {}

    // function setVote(proposalId) {}

    // // changer workflow status
    // function startProposalRegistration() onlyOwner {}

    // function startVotingSession() onlyOwner {}

    // function endVotingSession() onlyOwner {}
}
