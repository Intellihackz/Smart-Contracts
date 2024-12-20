// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecentralizedVoting {
    struct Voter {
        bool hasVoted;
        uint weight;
        address delegate;
        uint vote;
    }
    
    struct Proposal {
        bytes32 name;
        uint voteCount;
    }
    
    address public chairperson;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "Only chairperson can give right to vote");
        require(!voters[voter].hasVoted, "Voter already voted");
        require(voters[voter].weight == 0);
        
        voters[voter].weight = 1;
    }
    
    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(!sender.hasVoted, "Voter already voted");
        require(to != msg.sender, "Self-delegation is not allowed");
        
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation");
        }
        
        Voter storage delegate_ = voters[to];
        require(delegate_.weight >= 1);
        
        sender.delegate = to;
        
        if (delegate_.hasVoted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }
    
    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.hasVoted, "Already voted");
        
        sender.hasVoted = true;
        sender.vote = proposal;
        
        proposals[proposal].voteCount += sender.weight;
    }
    
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }
    
    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}
