// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FractionalPropertyInvestment {
    
    struct Property {
        string name;
        string location;
        uint256 totalShares;
        uint256 availableShares;
        uint256 pricePerShare;  // Price in wei
        mapping(address => uint256) sharesOwned;
        address[] investors;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
        mapping(address => bool) voters;
    }

    address public owner;
    mapping(uint256 => Property) public properties;
    uint256 public propertyCount;
    mapping(uint256 => Proposal[]) public proposals;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyInvestor(uint256 propertyId) {
        require(properties[propertyId].sharesOwned[msg.sender] > 0, "Not an investor in this property");
        _;
    }

    event PropertyAdded(uint256 propertyId, string name, string location, uint256 totalShares, uint256 pricePerShare);
    event SharesPurchased(uint256 propertyId, address investor, uint256 shares);
    event DividendPaid(uint256 propertyId, uint256 amount);
    event ProposalCreated(uint256 propertyId, uint256 proposalId, string description);
    event ProposalVoted(uint256 propertyId, uint256 proposalId, address voter);

    constructor() {
        owner = msg.sender;
    }

    function addProperty(string memory name, string memory location, uint256 totalShares, uint256 pricePerShare) public onlyOwner {
        propertyCount++;
        Property storage newProperty = properties[propertyCount];
        newProperty.name = name;
        newProperty.location = location;
        newProperty.totalShares = totalShares;
        newProperty.availableShares = totalShares;
        newProperty.pricePerShare = pricePerShare;

        emit PropertyAdded(propertyCount, name, location, totalShares, pricePerShare);
    }

    function buyShares(uint256 propertyId, uint256 numShares) public payable {
        Property storage property = properties[propertyId];
        require(property.availableShares >= numShares, "Not enough shares available");
        require(msg.value >= property.pricePerShare * numShares, "Insufficient payment");

        if (property.sharesOwned[msg.sender] == 0) {
            property.investors.push(msg.sender);
        }

        property.sharesOwned[msg.sender] += numShares;
        property.availableShares -= numShares;

        emit SharesPurchased(propertyId, msg.sender, numShares);
    }

    function payDividend(uint256 propertyId) public onlyOwner payable {
        Property storage property = properties[propertyId];
        uint256 totalDividend = msg.value;

        for (uint256 i = 0; i < property.investors.length; i++) {
            address investor = property.investors[i];
            uint256 investorShares = property.sharesOwned[investor];
            uint256 payment = (totalDividend * investorShares) / property.totalShares;
            payable(investor).transfer(payment);
        }

        emit DividendPaid(propertyId, msg.value);
    }

    function createProposal(uint256 propertyId, string memory description) public onlyInvestor(propertyId) {
        proposals[propertyId].push();
        uint256 proposalId = proposals[propertyId].length - 1;
        Proposal storage newProposal = proposals[propertyId][proposalId];
        newProposal.description = description;

        emit ProposalCreated(propertyId, proposalId, description);
    }

    function voteOnProposal(uint256 propertyId, uint256 proposalId) public onlyInvestor(propertyId) {
        Proposal storage proposal = proposals[propertyId][proposalId];
        require(!proposal.voters[msg.sender], "Already voted");

        proposal.voteCount += properties[propertyId].sharesOwned[msg.sender];
        proposal.voters[msg.sender] = true;

        emit ProposalVoted(propertyId, proposalId, msg.sender);
    }

    function getProposal(uint256 propertyId, uint256 proposalId) public view returns (string memory, uint256) {
        Proposal storage proposal = proposals[propertyId][proposalId];
        return (proposal.description, proposal.voteCount);
    }

    function getInvestorShares(uint256 propertyId, address investor) public view returns (uint256) {
        return properties[propertyId].sharesOwned[investor];
    }
}

