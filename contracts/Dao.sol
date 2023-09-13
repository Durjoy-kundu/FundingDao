// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
contract demo{
    struct Proposal{
     uint id;
    string description;
    uint amount;
    address payable receipient;
    uint votes;
    uint end;
    bool isExecuted;
    }
    mapping(address=>bool) private isInvestor;
    mapping(address=>uint) public numOfshares;
    mapping(address=>mapping(uint=>bool)) public isVoted;
    // mapping(address=>mapping(address=>bool)) public withdrawlStatus;
    address[] public investorsList;
    mapping(uint=>Proposal)public proposals;

    uint public totalShare;
    uint public availableFunds;
    uint public contributionTimeEnd;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public manager;

    constructor(uint _contributionTimeEnd, uint _voteTime , uint _quorum){
        require(_quorum>0 && _quorum<100, "Not valid values");
        contributionTimeEnd = block.timestamp + _contributionTimeEnd; // 4 pm + 36000
        voteTime = _voteTime;
        quorum = _quorum;
        manager = msg.sender;
    }

    modifier onlyInvestor(){
        require(isInvestor[msg.sender] == true, "you are not an investor");
        _;
    }

    modifier onlyManager(){
        require(manager == msg.sender, "you are not a manager");
        _;
    }

    function contribution() public payable{
        require(contributionTimeEnd >= block.timestamp,"contribution time ended");
        require(msg.value>0,"send more than 0 ether ");
        isInvestor[msg.sender] = true;
        numOfshares[msg.sender] = numOfshares[msg.sender]+msg.value; // uint value of ether - in wei
        totalShare += msg.value;
        availableFunds+=msg.value;
        investorsList.push(msg.sender);

    }

    //reedem share
    function reedemShare(uint amount) public onlyInvestor(){
        require(numOfshares[msg.sender]>=amount,"You dont have enough shares");
        require(availableFunds>=amount,"Not enough funds");
        numOfshares[msg.sender]-=amount;
        if(numOfshares[msg.sender] == 0){
            isInvestor[msg.sender]=false;
        }
        availableFunds-=amount;
        payable(msg.sender).transfer(amount); //typecasting - converting to payable address + transferring share

    }

    function transferShare(uint amount, address to) public onlyInvestor(){
        require(numOfshares[msg.sender]>=amount,"You dont have enough shares");
        require(availableFunds>=amount,"Not enough funds");
         if(numOfshares[msg.sender] == 0){
            isInvestor[msg.sender]=false;
        }
        availableFunds-=amount;
        numOfshares[to]+=amount;
        isInvestor[to] = true;
        investorsList.push(to);
        //payable(to).transfer(amount); // transferring share to another address
    }

    function createProposal(string calldata description, uint amount, address payable receipient ) public {
        require(availableFunds>=amount,"Not enough funds");
        proposals[nextProposalId] = Proposal(nextProposalId, description, amount, receipient,0,block.timestamp+voteTime,false);
        nextProposalId++;
    }


    function voteProposal(uint proposalId) public onlyInvestor(){
        Proposal storage proposal = proposals[proposalId];  // create a proposal variable to point voted mapping
        require(isVoted[msg.sender][proposalId] == false, "You have already voted for this proposal" );
        require(proposal.end>=block.timestamp,"voting time is over");
        require(proposal.isExecuted == false, "It is already executed ");
        isVoted[msg.sender][proposalId] = true;
        proposal.votes += numOfshares[msg.sender];

    }

    // execution function 
    // quorum is setted by 
    function executeProposal(uint proposalId) public onlyManager(){
        Proposal storage proposal = proposals[proposalId];
        require(((proposal.votes*100)/totalShare)>=quorum,"Majority doesn't support");
        proposal.isExecuted = true;
        availableFunds -= proposal.amount;
        _transfer(proposal.amount, proposal.receipient);
    }

    function _transfer(uint amount, address payable receipient) private {
        receipient.transfer(amount);
    }

    function ProposalList() public view returns(Proposal[] memory){
        Proposal[] memory arr = new Proposal[](nextProposalId - 1);
        for(uint i= 0; i<nextProposalId; i++){
            arr[i] = proposals[i];
        }
        return arr; // we can't return mapping from a function ; thats why we transfer in array then return as arry from function;
    }



}