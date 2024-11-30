// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DynamicNFT {
    struct NFTAttributes {
        uint level;
        uint experience;
        uint lastUpdateTime;
    }
    
    mapping(uint => NFTAttributes) public nftAttributes;
    mapping(uint => address) public nftOwners;
    uint public totalNFTs;
    
    event NFTMinted(uint indexed tokenId, address indexed owner);
    event NFTLeveledUp(uint indexed tokenId, uint newLevel);
    
    function mint() external returns (uint) {
        uint tokenId = totalNFTs;
        nftOwners[tokenId] = msg.sender;
        
        nftAttributes[tokenId] = NFTAttributes({
            level: 1,
            experience: 0,
            lastUpdateTime: block.timestamp
        });
        
        totalNFTs++;
        emit NFTMinted(tokenId, msg.sender);
        return tokenId;
    }
    
    function addExperience(uint tokenId, uint exp) external {
        require(nftOwners[tokenId] == msg.sender, "Not the owner");
        
        NFTAttributes storage nft = nftAttributes[tokenId];
        nft.experience += exp;
        
        // Simple leveling mechanism
        if (nft.experience >= nft.level * 100) {
            nft.level++;
            nft.experience = 0;
            emit NFTLeveledUp(tokenId, nft.level);
        }
        
        nft.lastUpdateTime = block.timestamp;
    }
    
    function getNFTDetails(uint tokenId) external view returns (NFTAttributes memory) {
        return nftAttributes[tokenId];
    }
}
