# Voting Contract

## Overview

This smart contract is a school project making basic use of solidity fundamentals.
My aim was to implement a draft of a voting system designed to ensure a democratic and fair process in decision-making scenarios, while maintaining security and controlling function calls.

Do note the project is 2-fold:

- `Voting.sol` adheres to my school project requirements
- `VotingPlus.sol` is my extra mile, introducing what i believe to be improvements built on the original project

Find more information pertaining to the project in the following files:

- requirements.md
- differences.txt

## Challenges

I made little to no effort on refactoring and making my code more modular. At this point I am still very new to Solidity and thus, I decided to spend time on making a voting system that is somewhat feature-rich rather than very well structured and reusable. I figured it was good practice and that I have the rest of my life to hone my skills in refactoring!

To the people that may fiind the project very difficult to sift through, please undestand my perspective and accept my apologies!

Additionally, I found that testing was extremely cumbersome & timeconsuming through Remix, it's likely there are issues overall, and flaws in the logic here and there due to the tedious experience in the aforementioned tool.

## Features

- **Voter Registration**: Admins can register voters, ensuring controlled participation
- **Proposal Registration**: Registered voters can submit proposals during a designated period

- **Admin Inclusion Voting [VotingPlus.sol]**: Special voting session to decide if the admin can vote
- **Vote Delegation [VotingPlus.sol]**: Voters can delegate their votes to others, enhancing flexibility
- **Voting Sessions**: Period for voters to cast votes on registered proposals
- **Runoff Voting [VotingPlus.sol]**: In case of a tie, a runoff vote is conducted to determine the winner
- **Event broacast**: Relevant events are broadcast throughout the voting process
- **Workflow Status Management**: Voting process is broken down different stages

## Events

- `VoterRegistered`, `AdminRegisteredAsVote [VotingPlus.sol]`: Triggered when voters are registered
- `WorkflowStatusChange`: Indicates a change in the voting process stage
- `ProposalRegistered`: Emitted when a new proposal is registered
- `Voted`, `VotedInRunoff [VotingPlus.sol]`: Captures when votes are cast in different stages
- `DelegatedVote [VotingPlus.sol]`: Notifies when a vote is delegated
- `VotedProposal`, `NoProposalVoted`, `TiedProposals [VotingPlus.sol]`: Related to the outcome of voting sessions

## Error Handling

- Custom errors for each stage of the workflow to manage exceptions effectively

## Usage

1. **Deploy the Contract**: Initialize by deploying the contract to Remix
2. **Register Voters**: Admin can add voters before the proposal registration begins
3. **Submit Proposals**: During the proposal registration phase, voters can submit their proposals
4. **Admin Inclusion [VotingPlus.sol]**: Voters are subject to a vote to determine whether the admin can take part in subsequent votes
5. **Vote Delegation [VotingPlus.sol]**: Voters are given the opportunity to delegate their vote to a proxy
6. **Conduct Voting Sessions**: The voting session for proposals may start and voters cast their votes
7. **Tally Votes**: Once voting concludes, tally the votes to determine the winning proposal
8. **Handle Runoff [VotingPlus.sol]**: If there's a tie, initiate a runoff vote

## Requirements

- Solidity ^0.8.22
- OpenZeppelin Contracts (for `Ownable.sol`)

## License

This project is licensed under the MIT License.
