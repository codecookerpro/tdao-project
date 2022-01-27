pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./AuthorEntity.sol";
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

/// @title Talent DAO NFT Contract
/// @author Jaxcoder
/// @dev ERC721 to represent articles submitted by authors
contract TalentDaoNftToken is Ownable, ERC721URIStorage, AuthorEntity {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private _tokenIds;

    address public treasury;

    constructor(address _owner) public ERC721("Talent DAO NFT", "TDAO") {
        _transferOwnership(_owner);
    }

    /// @dev we may not need this, for OpenSea
    function contractURI() public view returns (string memory) {
        return "";
    }

    /// @dev this is internal mint function
    /// @param author the user that is minting the token address
    /// @param arweaveHash the arweave hash for the article
    /// @param metadataPtr the metadata uri for the nft
    function mintAuthorNFT(address author, bytes32 arweaveHash, string memory metadataPtr)
        public
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        addArticle(author, arweaveHash);
        Article storage article = articles[arweaveHash];
        article.author = author;
        article.metadataPtr = metadataPtr;
        article.tokenId = newItemId;
        
        _mint(author, newItemId);
        _setTokenURI(newItemId, metadataPtr);

        return newItemId;
    }

    /// @dev this is internal mint function
    /// @param author the user that is minting the token address
    /// @param arweaveHash the hash of the article
    /// @param metadataPtr the metadata uri for the nft
    /// @param token the token address of the asset to pay with
    /// @param amount the amount of tdao tokens submitting
    function mintAuthorNFT(address author, bytes32 arweaveHash, string memory metadataPtr, address token, uint256 amount)
        public
        returns (uint256)
    {
        require(IERC20(token).balanceOf(msg.sender) > amount, "");
        IERC20(token).transferFrom(author, address(this), amount);

        _tokenIds.increment();
        (uint256 articleId) = addArticle(author, arweaveHash);
        Article storage article = articles[arweaveHash];
        article.author = author;
        article.metadataPtr = metadataPtr;
        article.paid = amount;

        (uint256 authorId) = addAuthor(author, articleId);
        article = authorsArticlesById[author][articleId];

        uint256 newItemId = _tokenIds.current();
        _mint(author, newItemId);
        _setTokenURI(newItemId, metadataPtr);

        return newItemId;
    }

    /// @dev public function to set the token URI
    /// @param _tokenId the id of the token to update
    /// @param _tokenURI the new token URI
    function setTokenURI
    (
        uint256 _tokenId,
        string memory _tokenURI
    )
        public
        onlyOwner
    {
        _setTokenURI(_tokenId, _tokenURI);
    }
}
