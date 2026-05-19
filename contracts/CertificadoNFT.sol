// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/*
    NFT para representar certificados digitais ou badges.
*/
contract CertificadoNFT is ERC721URIStorage, Ownable {
    uint256 public nextTokenId = 1;

    event CertificateMinted(address indexed to, uint256 indexed tokenId, string tokenURI);

    constructor() ERC721("EduStake Certificate", "EDUCERT") Ownable(msg.sender) {}

    function mintCertificate(address to, string memory metadataURI) external onlyOwner returns (uint256) {
        require(to != address(0), "Invalid recipient.");
        require(bytes(metadataURI).length > 0, "Token URI cannot be empty.");

        uint256 tokenId = nextTokenId;
        nextTokenId += 1;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataURI);

        emit CertificateMinted(to, tokenId, metadataURI);
        return tokenId;
    }
}
