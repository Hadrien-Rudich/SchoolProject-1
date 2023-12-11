//SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        // added addresss for easier manipulation
        address voterAddress;
        bool isRegistered;
        // replaced hasVoted with voting weight, additional weight can be acquired from delegation
        uint weight;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    uint private winningProposalId;
    int private adminInclusionValue;

    // array that helps with assertions and prevents overusing loops
    Voter[] private voters;
    // array that makes returning proposals easier, see get functions
    Proposal[] private proposals;
    // array to store tiedProposals for a runoff vote
    Proposal[] private tiedProposals;

    // variable ensuring at least one vote has been cast, see endVotingSession
    bool private haveVotesBeenCast = false;

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
        // Additional statuses to integrate an admin rights vote
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        // Additional statuses to include the admin as registered voter
        AdminInclusionStarted,
        AdminInclusionEnded,
        // Additional statuses to integrate a delegation window
        VoteDelegationStarted,
        VoteDelegationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied,
        // additional statuses to deal with tied proposals
        RunOffVoteStarted,
        RunOffVoteEnded
    }

    WorkflowStatus private defaultStatus = WorkflowStatus.RegisteringVoters;

    event VoterRegistered(address voterAddress);
    event AdminRegisteredAsVoter(address adminAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);
    // new event for runoff vote
    event VotedInRunoff(address voter, uint proposalId);
    // new event for vote delegation
    event DelegatedVote(address voter, address beneficiary);
    // new event for admin inclusion vote
    event VotedOnAdminInclusion(address voter);
    // new events for (un)voted proposal
    event VotedProposal(uint proposalId);
    event NoProposalVoted();
    // new event for tied proposals
    event TiedProposals();

    error ProposalRegistrationAlreadyStarted();
    error ProposalRegistrationAlreadyEnded();
    // new errors to deal with admin inclusion and vote delegation windows
    error AdminInclusionAlreadyStarted();
    error AdminInclusionAlreadyEnded();
    error VoteDelegationAlreadyStarted();
    error VoteDelegationAlreadyEnded();
    error VotingAlreadyStarted();
    error VotingAlreadyEnded();
    // new errors to deal with runoff votes
    error RunoffVoteAlreadyStarted();
    error RunoffVoteAlreadyEnded();

    constructor() Ownable(msg.sender) {}

    function addVoter(address _address) external onlyOwner {
        require(
            defaultStatus == WorkflowStatus.RegisteringVoters,
            "Voter registration window has ended"
        );

        require(_address != msg.sender, "Admin cannot self-register as voter");
        // initializing new voters with a weight of 1 and votedProposalId at 0
        Voter memory newVoter = Voter(_address, true, 1, 0);

        registeredVoters[_address] = newVoter;
        voters.push(newVoter);
        emit VoterRegistered(_address);
    }

    // function to add admin as voter in the event that the admin inclusion vote is in his favor
    function includeAdminAsVoter() private {
        Voter memory newVoter = Voter({
            voterAddress: msg.sender,
            isRegistered: true,
            weight: 1,
            votedProposalId: 0
        });

        registeredVoters[msg.sender] = newVoter;
        voters.push(newVoter); // Push the new voter to the voters array

        emit AdminRegisteredAsVoter(msg.sender);
    }

    function getVoterCount() external view returns (uint) {
        require(voters.length > 0, "No registered voter");
        return voters.length;
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
        require(
            _proposalId > 0 && _proposalId <= proposals.length,
            "Invalid proposal ID"
        );
        require(
            registeredVoters[msg.sender].weight > 0,
            "A vote has already been registered or delegated"
        );

        uint proposalIndex = _proposalId - 1;
        proposals[proposalIndex].voteCount++;
        registeredVoters[msg.sender].weight -= 1;
        haveVotesBeenCast = true;

        registeredVoters[msg.sender].votedProposalId = _proposalId;
        emit Voted(msg.sender, _proposalId);
    }

    function castAdminInclusionVote(bool vote) external onlyVoter {
        require(
            defaultStatus == WorkflowStatus.AdminInclusionStarted,
            "Admin inclusion window currently closed"
        );
        require(
            registeredVoters[msg.sender].weight > 0,
            "Vote has already been cast"
        );

        if (vote) {
            adminInclusionValue += 1;
        } else {
            adminInclusionValue -= 1;
        }
        registeredVoters[msg.sender].weight -= 1;

        emit VotedOnAdminInclusion(msg.sender);
    }

    function delegateVote(address _address) external onlyVoter {
        require(
            registeredVoters[_address].isRegistered,
            "Address is not a registered voter"
        );
        require(
            defaultStatus == WorkflowStatus.VoteDelegationStarted,
            "Vote delegation has not started"
        );
        require(
            registeredVoters[msg.sender].weight > 0,
            "Delegation was already granted"
        );
        require(msg.sender != _address, "Cannot delegate to self");

        // delegator has voting weight decreased by 1, beneficiary increased by 1
        registeredVoters[msg.sender].weight -= 1;
        registeredVoters[_address].weight += 1;
        emit DelegatedVote(msg.sender, _address);
    }

    function getWinningProposal() external view returns (uint) {
        require(
            defaultStatus == WorkflowStatus.VotesTallied,
            "Votes have yet to be tallied"
        );

        return winningProposalId;
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

    function startAdminInclusionVote() external onlyOwner {
        if (defaultStatus == WorkflowStatus.AdminInclusionStarted) {
            revert AdminInclusionAlreadyStarted();
        }
        require(
            defaultStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "Admin inclusion vote cannot be started"
        );

        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.AdminInclusionStarted
        );
        defaultStatus = WorkflowStatus.AdminInclusionStarted;
    }

    function endAdminInclusionVote() external onlyOwner {
        if (defaultStatus == WorkflowStatus.AdminInclusionEnded) {
            revert AdminInclusionAlreadyEnded();
        }
        require(
            defaultStatus == WorkflowStatus.AdminInclusionStarted,
            "Admin inclusion vote has not started"
        );
        emit WorkflowStatusChange(
            WorkflowStatus.AdminInclusionStarted,
            WorkflowStatus.AdminInclusionEnded
        );
        defaultStatus = WorkflowStatus.AdminInclusionEnded;

        if (adminInclusionValue > 0) {
            includeAdminAsVoter();
        }
    }

    function startVoteDelegation() external onlyOwner {
        if (defaultStatus == WorkflowStatus.VoteDelegationStarted) {
            revert VoteDelegationAlreadyStarted();
        }

        require(
            defaultStatus == WorkflowStatus.AdminInclusionEnded,
            "Vote delegation cannot be started"
        );

        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VoteDelegationStarted
        );
        defaultStatus = WorkflowStatus.VoteDelegationStarted;
    }

    function endVoteDelegation() external onlyOwner {
        if (defaultStatus == WorkflowStatus.VoteDelegationEnded) {
            revert VoteDelegationAlreadyEnded();
        }

        require(
            defaultStatus == WorkflowStatus.VoteDelegationStarted,
            "Vote delegation has not started"
        );

        emit WorkflowStatusChange(
            WorkflowStatus.VoteDelegationStarted,
            WorkflowStatus.VoteDelegationEnded
        );
        defaultStatus = WorkflowStatus.VoteDelegationEnded;
    }

    function startVotingSession() external onlyOwner {
        if (defaultStatus == WorkflowStatus.VotingSessionStarted) {
            revert VotingAlreadyStarted();
        }

        require(
            defaultStatus == WorkflowStatus.VoteDelegationEnded,
            "Voting session cannot be started"
        );
        resetVoterWeights();

        emit WorkflowStatusChange(
            WorkflowStatus.VoteDelegationEnded,
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

        require(haveVotesBeenCast, "No votes have been cast");

        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
        defaultStatus = WorkflowStatus.VotingSessionEnded;
    }

    function tallyVotes() external onlyOwner {
        require(
            defaultStatus == WorkflowStatus.VotingSessionEnded,
            "Voting tally window has yet to start"
        );

        // Clear existing tiedProposals
        delete tiedProposals;

        Proposal memory mostVotedProposal = Proposal("", 0);
        bool isTie = false;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > mostVotedProposal.voteCount) {
                mostVotedProposal = proposals[i];
                winningProposalId = i + 1;
                // Clear tiedProposals if a new most voted proposal is found
                delete tiedProposals;
                isTie = false;
            } else if (proposals[i].voteCount == mostVotedProposal.voteCount) {
                if (proposals[i].voteCount != 0) {
                    // Ensure not to add proposals with 0 votes
                    tiedProposals.push(proposals[i]);
                    if (!isTie) {
                        // Add the previously most voted proposal if this is the first tie found
                        tiedProposals.push(mostVotedProposal);
                        isTie = true;
                    }
                    winningProposalId = 0;
                }
            }
        }

        // Emit appropriate events based on the result
        if (winningProposalId != 0) {
            emit VotedProposal(winningProposalId);
        } else if (isTie) {
            emit TiedProposals();
        } else {
            emit NoProposalVoted();
        }

        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
        defaultStatus = WorkflowStatus.VotesTallied;
    }

    // function allowing us to easily reset voter weights in-between voting sessions
    function getVoterAddress(uint index) private view returns (address) {
        require(index < voters.length, "Invalid index");
        return voters[index].voterAddress;
    }

    function resetVoterWeights() private {
        for (uint i = 0; i < voters.length; i++) {
            address voterAddress = getVoterAddress(i);
            registeredVoters[voterAddress].weight = 1;
        }
    }

    function startRunoffVote() external onlyOwner {
        if (defaultStatus == WorkflowStatus.RunOffVoteStarted) {
            revert RunoffVoteAlreadyStarted();
        }

        require(
            defaultStatus == WorkflowStatus.VotesTallied,
            "Runoff vote cannot be started"
        );
        // reset voters for runoff
        resetVoterWeights();

        emit WorkflowStatusChange(
            WorkflowStatus.VotesTallied,
            WorkflowStatus.RunOffVoteStarted
        );
        defaultStatus = WorkflowStatus.RunOffVoteStarted;
    }

    function endRunoffVote() external onlyOwner {
        if (defaultStatus == WorkflowStatus.RunOffVoteEnded) {
            revert RunoffVoteAlreadyEnded();
        }

        require(
            defaultStatus == WorkflowStatus.RunOffVoteStarted,
            "Runoff vote has not started"
        );

        emit WorkflowStatusChange(
            WorkflowStatus.RunOffVoteStarted,
            WorkflowStatus.RunOffVoteEnded
        );
        defaultStatus = WorkflowStatus.RunOffVoteEnded;
    }

    function getTiedProposals() external view returns (Proposal[] memory) {
        return tiedProposals;
    }

    function castRunoffVote(uint _proposalId) external onlyVoter {
        require(
            defaultStatus == WorkflowStatus.RunOffVoteStarted,
            "Runoff voting window currently closed"
        );
        require(_proposalId <= tiedProposals.length - 1, "Invalid proposal ID");
        require(
            registeredVoters[msg.sender].weight > 0,
            "A vote has already been registered or delegated"
        );

        tiedProposals[_proposalId].voteCount++;
        registeredVoters[msg.sender].weight -= 1;
        haveVotesBeenCast = true;

        registeredVoters[msg.sender].votedProposalId = _proposalId;
        emit VotedInRunoff(msg.sender, _proposalId);
    }

    // tallyVote for runoff scenarios
    function tallyRunoffVotes() external onlyOwner {
        require(
            defaultStatus == WorkflowStatus.RunOffVoteEnded,
            "Runoff voting tally has yet to start"
        );

        uint highestVoteCount = 0;
        uint winningRunoffProposalId = 0;

        for (uint i = 0; i < tiedProposals.length; i++) {
            if (tiedProposals[i].voteCount > highestVoteCount) {
                highestVoteCount = tiedProposals[i].voteCount;
                winningRunoffProposalId = i + 1;
            }
        }

        if (winningRunoffProposalId != 0) {
            emit VotedProposal(winningRunoffProposalId);
        } else {
            emit NoProposalVoted();
        }

        winningProposalId = winningRunoffProposalId;

        emit WorkflowStatusChange(
            WorkflowStatus.RunOffVoteEnded,
            WorkflowStatus.VotesTallied
        );
        defaultStatus = WorkflowStatus.VotesTallied;
    }
}
