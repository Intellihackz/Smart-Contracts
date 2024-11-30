// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TokenVesting {
    address public beneficiary;
    uint public total;
    uint public released;
    uint public start;
    uint public duration;
    
    constructor(address _beneficiary, uint _total, uint _duration) {
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_duration > 0, "Duration must be > 0");
        
        beneficiary = _beneficiary;
        total = _total;
        start = block.timestamp;
        duration = _duration;
    }
    
    function calculateReleasableAmount() public view returns (uint) {
        uint currentTime = block.timestamp;
        uint elapsedTime = currentTime - start;
        
        if (elapsedTime <= duration) {
            uint vestedAmount = (total * elapsedTime) / duration;
            return vestedAmount - released;
        }
        
        return total - released;
    }
    
    function release() external {
        uint releasableAmount = calculateReleasableAmount();
        require(releasableAmount > 0, "No tokens to release");
        
        released += releasableAmount;
        (bool success, ) = beneficiary.call{value: releasableAmount}("");
        require(success, "Transfer failed");
    }
}
