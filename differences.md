`VOTING.SOL`

Considering the requirements & instructions for creating this Voting System, there was room for interpretation and personal preference.
As such, you will find below the arbitrary decisions I made for my basic implementation:

- The Admin cannot self-register as voter
- At least 3 voters are needed
- At least 2 proposals are needed
- At least 1 vote is needed
- Ties are not resolved, in such an event, the proposal with the smaller index wins
- proposalId starts at 1, leaving 0 as default non-existing proposalId

`VOTINGPLUS.SOL`

In a more advanced version, I implemented the following improvements/additions:

- Voters are now subject to a new vote that determines whether they agree to the Admin takin part in voting
- Voters can now delegate their vote
- There is a runoff vote for resolving ties

If I had more time and proficiency, I would have also considered:

- No minimum amount of proposal/vote anymore, workflow changes happen over time after X number of created blocks
- Ability to reset a vote after tally, keeping history of winning proposals
- Think of a solution for runoff votes that result in yet another tie
