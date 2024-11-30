// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint confirmations;
    }
    
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;
    
    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;
    
    event Deposit(address indexed sender, uint value);
    event Submission(uint indexed txIndex);
    event Confirmation(address indexed owner, uint indexed txIndex);
    event Execution(uint indexed txIndex);
    
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required confirmations");
        
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Duplicate owner");
            
            isOwner[owner] = true;
            owners.push(owner);
        }
        
        required = _required;
    }
    
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    function submitTransaction(address _to, uint _value, bytes memory _data) 
        public 
        onlyOwner 
        returns (uint)
    {
        uint txIndex = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            confirmations: 0
        }));
        
        emit Submission(txIndex);
        return txIndex;
    }
    
    function confirmTransaction(uint _txIndex) public onlyOwner {
        require(_txIndex < transactions.length, "Transaction doesn't exist");
        require(!confirmations[_txIndex][msg.sender], "Transaction already confirmed");
        
        confirmations[_txIndex][msg.sender] = true;
        transactions[_txIndex].confirmations++;
        
        emit Confirmation(msg.sender, _txIndex);
    }
    
    function executeTransaction(uint _txIndex) public onlyOwner {
        Transaction storage transaction = transactions[_txIndex];
        require(!transaction.executed, "Transaction already executed");
        require(transaction.confirmations >= required, "Not enough confirmations");
        
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");
        
        emit Execution(_txIndex);
    }
    
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }
}
