//SPDX-License-Identifier: MIT

// Le smart contract doit utiliser la dernière version du compilateur
pragma solidity 0.8.22;

// Le smart contract doit utiliser la librairie `Ownable` d'OpenZeppelin
import "@openzeppelin/contracts/access/Ownable.sol";

// Le smart contract doit être nommé `Voting`
contract Voting is Ownable {
    // Le smart contract doit définir un uint représentant la proposition gagnante

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

    Proposal[] private proposals;
    uint private winningProposalId = type(uint).max;

    mapping(address => bool) whitelist;

    modifier onlyVoter() {
        require(whitelist[msg.sender], "Restricted to authorized voters");
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

    function addVoter(address _address) external onlyOwner {
        whitelist[_address] = true;
    }

    function getVoter(address _address) external view returns (bool) {
        return whitelist[_address];
    }

    function addProposal(string calldata _description) external onlyVoter {
        Proposal memory newProposal = Proposal(_description, 0);
        proposals.push(newProposal);
    }

    function getProposals() external view returns (Proposal[] memory) {
        return proposals;
    }

    function castVote(uint _proposalId) external onlyVoter {
        require(_proposalId <= proposals.length, "Invalid proposal ID");
        Proposal storage selectedProposal = proposals[_proposalId];
        selectedProposal.voteCount++;
    }

    function getWinningProposal() external view returns (uint) {
        require(
            winningProposalId != type(uint).max,
            "The vote has yet to decide a winner"
        );
        return winningProposalId;
    }
}

// // changer workflow status
// function startProposalRegistration() onlyOwner {}

// function startVotingSession() onlyOwner {}

// function endVotingSession() onlyOwner {}
