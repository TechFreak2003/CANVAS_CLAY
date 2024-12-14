// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimplifiedMarketplace is ERC721URIStorage, Ownable {
    struct NFTDetails {
        uint256 price;
        address creator; // Original creator for royalties
        bool isListed;   // Whether the NFT is currently listed for sale
    }

    mapping(uint256 => NFTDetails) public nftDetails;

    uint256 public listingFee = 0.0018 ether;
    uint256 public royaltyPercentage = 5;
    uint256 private _tokenIdCounter;

    event NFTMinted(uint256 tokenId, address creator, string cid);
    event NFTListed(uint256 tokenId, uint256 price, address creator);
    event NFTBought(uint256 tokenId, address buyer, uint256 price, address seller);
    event NFTResold(uint256 tokenId, uint256 price, address seller);

    // Constructor: Pass the owner address explicitly to Ownable
    constructor(string memory name, string memory symbol, address initialOwner)
        ERC721(name, symbol)
        Ownable(initialOwner)
    {}

    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner");
        _;
    }

    function mintAndStoreCID(string memory cid) external {
        uint256 tokenId = _tokenIdCounter++;
        _mint(msg.sender, tokenId);

        // Set the tokenURI using the provided CID
        string memory tokenURI = string(abi.encodePacked("ipfs://", cid));
        _setTokenURI(tokenId, tokenURI);

        nftDetails[tokenId] = NFTDetails({
            price: 0,
            creator: msg.sender,
            isListed: false
        });

        emit NFTMinted(tokenId, msg.sender, cid);
    }

    function listNFT(uint256 tokenId, uint256 price) external payable onlyOwnerOf(tokenId) {
        require(msg.value >= listingFee, "Insufficient listing fee");
        require(price > 0, "Price must be greater than 0");

        nftDetails[tokenId].price = price;
        nftDetails[tokenId].isListed = true;

        // Send listing fee to contract owner
        payable(owner()).transfer(msg.value);

        emit NFTListed(tokenId, price, nftDetails[tokenId].creator);
    }

    function buyNFT(uint256 tokenId) external payable {
        NFTDetails memory nft = nftDetails[tokenId];
        require(nft.isListed, "NFT is not listed for sale");
        require(msg.value >= nft.price, "Insufficient payment");

        address seller = ownerOf(tokenId);
        uint256 royalty = (msg.value * royaltyPercentage) / 100;
        uint256 sellerAmount = msg.value - royalty;

        // Transfer Ether to seller and royalties to creator
        payable(seller).transfer(sellerAmount);
        payable(nft.creator).transfer(royalty);

        // Transfer ownership of the NFT
        _transfer(seller, msg.sender, tokenId);
        nftDetails[tokenId].isListed = false;

        emit NFTBought(tokenId, msg.sender, nft.price, seller);
    }

    function resellNFT(uint256 tokenId, uint256 price) external payable onlyOwnerOf(tokenId) {
        require(msg.value >= listingFee, "Insufficient listing fee");
        require(price > 0, "Price must be greater than 0");

        nftDetails[tokenId].price = price;
        nftDetails[tokenId].isListed = true;

        // Send listing fee to contract owner
        payable(owner()).transfer(msg.value);

        emit NFTResold(tokenId, price, msg.sender);
    }

    // Receive Ether function to allow the contract to accept Ether
    receive() external payable {}

    // Fallback function to accept Ether sent with data
    fallback() external payable {}

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
} 