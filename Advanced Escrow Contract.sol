// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AdvancedEscrow {
    address public buyer;
    address public seller;
    address public arbiter;
    uint public amount;
    bool public fundsDisbursed;
    
    enum State { Created, Locked, Completed, Refunded }
    State public currentState;
    
    event FundsDeposited(address depositor, uint amount);
    event DisputeResolved(address winner, uint amount);
    
    constructor(address _seller, address _arbiter) payable {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        amount = msg.value;
        currentState = State.Created;
    }
    
    modifier inState(State _state) {
        require(currentState == _state, "Invalid state");
        _;
    }
    
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call");
        _;
    }
    
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call");
        _;
    }
    
    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call");
        _;
    }
    
    function confirmDelivery() external onlySeller inState(State.Created) {
        currentState = State.Locked;
    }
    
    function confirmReceived() external onlyBuyer inState(State.Locked) {
        currentState = State.Completed;
        (bool success, ) = seller.call{value: amount}("");
        require(success, "Transfer failed");
        fundsDisbursed = true;
    }
    
    function resolveDispute(address payable winner) external onlyArbiter {
        require(currentState == State.Locked, "Can only resolve during locked state");
        currentState = State.Refunded;
        (bool success, ) = winner.call{value: amount}("");
        require(success, "Transfer failed");
        emit DisputeResolved(winner, amount);
    }
    
    function refund() external onlyBuyer inState(State.Locked) {
        currentState = State.Refunded;
        (bool success, ) = buyer.call{value: amount}("");
        require(success, "Refund failed");
    }
}
