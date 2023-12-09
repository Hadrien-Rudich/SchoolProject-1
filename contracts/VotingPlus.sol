//SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    uint private winningProposalId = type(uint).max;
    Voter[] private voters;
    Proposal[] private proposals;
    mapping(address => Voter) registeredVoters;

    modifier onlyVoter() {
        require(
            registeredVoters[msg.sender].isRegistered,
            "Restricted to registered voters"
        );
        _;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus private defaultStatus = WorkflowStatus.RegisteringVoters;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    error ProposalRegistrationAlreadyStarted();
    error ProposalRegistrationAlreadyEnded();
    error VotingAlreadyStarted();
    error VotingAlreadyEnded();

    constructor() Ownable(msg.sender) {}

    function addVoter(address _address) external onlyOwner {
        require(
            defaultStatus == WorkflowStatus.RegisteringVoters,
            "Voter registration window has ended"
        );

        require(_address != msg.sender, "Admin cannot be registered as voter");
        Voter memory newVoter = Voter(true, false, 0);
        registeredVoters[_address] = newVoter;
        voters.push(newVoter);
        emit VoterRegistered(_address);
    }

    function getVoters() external view returns (Voter[] memory) {
        require(voters.length > 0, "No registered voter");
        return voters;
    }

    function getVoter(address _address) external view returns (Voter memory) {
        require(
            registeredVoters[_address].isRegistered,
            "Address is not a registered voter"
        );
        return registeredVoters[_address];
    }

    function addProposal(string calldata _description) external onlyVoter {
        require(
            defaultStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposal registration window currently closed"
        );
        Proposal memory newProposal = Proposal(_description, 0);
        proposals.push(newProposal);
        emit ProposalRegistered(proposals.length - 1);
    }

    function getProposals() external view returns (Proposal[] memory) {
        require(
            defaultStatus != WorkflowStatus.RegisteringVoters,
            "Proposal registration has yet to start"
        );
        require(proposals.length > 0, "No registered proposal");
        return proposals;
    }

    function castVote(uint _proposalId) external onlyVoter {
        require(
            defaultStatus == WorkflowStatus.VotingSessionStarted,
            "Voting window currently closed"
        );
        require(_proposalId < proposals.length, "Invalid proposal ID");
        require(
            registeredVoters[msg.sender].hasVoted == false,
            "A vote has already been submitted"
        );
        proposals[_proposalId].voteCount++;
        registeredVoters[msg.sender].hasVoted = true;
        registeredVoters[msg.sender].votedProposalId = _proposalId;
        emit Voted(msg.sender, _proposalId);
    }

    function getWinningProposal() external view returns (uint) {
        require(
            defaultStatus == WorkflowStatus.VotesTallied,
            "Votes have yet to be tallied"
        );

        return winningProposalId;
    }

    function tallyVotes() external onlyOwner returns (Proposal memory) {
        require(
            defaultStatus == WorkflowStatus.VotingSessionEnded,
            "Voting tally window has yet to start"
        );

        Proposal memory mostVotedProposal = Proposal("", 0);

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > mostVotedProposal.voteCount) {
                mostVotedProposal = proposals[i];
                winningProposalId = i;
            }
        }
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
        defaultStatus = WorkflowStatus.VotesTallied;
        return mostVotedProposal;
    }

    function startProposalRegistration() external onlyOwner {
        if (defaultStatus == WorkflowStatus.ProposalsRegistrationStarted) {
            revert ProposalRegistrationAlreadyStarted();
        }

        require(
            defaultStatus == WorkflowStatus.RegisteringVoters,
            "Proposal registration cannot be started"
        );

        require(voters.length >= 3, "At least 3 registered voters needed");

        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            WorkflowStatus.ProposalsRegistrationStarted
        );
        defaultStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function endProposalRegistration() external onlyOwner {
        if (defaultStatus == WorkflowStatus.ProposalsRegistrationEnded) {
            revert ProposalRegistrationAlreadyEnded();
        }

        require(
            defaultStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposal registration cannot be ended"
        );

        require(
            proposals.length >= 2,
            "At least 2 registered proposals needed"
        );

        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            WorkflowStatus.ProposalsRegistrationEnded
        );
        defaultStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function startVotingSession() external onlyOwner {
        if (defaultStatus == WorkflowStatus.VotingSessionStarted) {
            revert VotingAlreadyStarted();
        }

        require(
            defaultStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "Voting session cannot be started"
        );

        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VotingSessionStarted
        );
        defaultStatus = WorkflowStatus.VotingSessionStarted;
    }

    function endVotingSession() external onlyOwner {
        if (defaultStatus == WorkflowStatus.VotingSessionEnded) {
            revert VotingAlreadyEnded();
        }

        require(
            defaultStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session has not started"
        );
        bool hasVotes = false;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > 0) {
                hasVotes = true;
                break;
            }
        }

        require(hasVotes, "No votes have been cast");

        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
        defaultStatus = WorkflowStatus.VotingSessionEnded;
    }
}
