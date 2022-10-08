// contracts/BlockPassTicket.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
//This implementation of ERC721 is used so that we store the tokenURIs on chain in storage, which is what allows us to store the metadata we upload to IPFS off-chain.
// https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721URIStorage
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
import "@openzeppelin/contracts/utils/Counters.sol";

contract BlockPassTicket is ERC721URIStorage, ERC2981, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    event NFTMinted(uint256);
    // event for scanning of token
    event TokenScanned(uint256);
    // event for invalidated
    event TokenInvalidated(uint256);
    // the wallet address of the event organizer
    address eventOrganizer;
    // the address of the marketplace contract
    address marketplaceContract;
    // the primary token sale price
    uint256 primarySalePrice;
    // the max percentage a token can be marked up if resold before the event.
    uint8 secondaryMarkup; // ex. 0.1 for 10%
    // the max supply of tickets that can be minted
    uint256 supply;
    // the uri pointing to the token asset
    string _tokenURI;
    // the state of a token
    enum tokenState {
        SOLD,
        SCANNED,
        INVALIDATED
    }
    // mapping of token ids to its state
    mapping(uint256 => tokenState) tokenStates;

    // start date of event in UTC milliseconds
    uint256 startDate;
    // end date of the event in UTC milliseconds
    uint256 endDate;

    // https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721URIStorage-tokenURI-uint256-

    constructor(
        address _marketplaceContract,
        address _eventOrganizer,
        string memory tokenURI,
        uint256 _primarySalePrice,
        uint8 _secondaryMarkup,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _supply
    ) ERC721("BlockPassTicket", "BPT") {
        require(
            _eventOrganizer != address(0),
            "Event organizer can't be the zero address"
        );
        require(
            _marketplaceContract != address(0),
            "Marketplace contract can't be the zero address"
        );
        require(
            _endDate >= block.timestamp,
            "Event end date can't be in the past"
        );
        require(
            _startDate <= _endDate,
            "Invalid start and end date relationship."
        );
        require(_supply > 0, "Supply must be greater than zero");
        require(bytes(tokenURI).length != 0, "Token URI must not be empty");
        // set event organizer royalty to be 10%
        _setDefaultRoyalty(_eventOrganizer, 1000);
        marketplaceContract = _marketplaceContract;
        eventOrganizer = _eventOrganizer;
        _tokenURI = tokenURI;
        primarySalePrice = _primarySalePrice;
        secondaryMarkup = _secondaryMarkup;
        startDate = _startDate;
        endDate = _endDate;
        supply = _supply;

    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // override the _burn function so that it also clears the royalty information for a burnt token
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    // burn function for external accounts.
    function burnNFT(uint256 tokenId) public {
        _burn(tokenId);
    }

    function mintNFT(address recipient)
        public
        whenNotPaused
        onlyOwner
        returns (uint256)
    {
        require(
            block.timestamp <= endDate,
            "Unable to mint tokens after the event has passed"
        );
        require(_tokenIds.current() < supply, "Ticket supply sold out");
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(recipient, newItemId);
        tokenStates[newItemId] = tokenState.SOLD;
        _setTokenURI(newItemId, _tokenURI);
        _setApprovalForAll(recipient, owner(), true);
        emit NFTMinted(newItemId);

        return newItemId;
    }

    function getEventOrganizer() public view returns (address) {
        return eventOrganizer;
    }

    function getMarketplaceContract() public view returns (address) {
        return marketplaceContract;
    }

    function getTotalTicketSupply() public view returns (uint256) {
        return supply;
    }

    function getTotalTicketsForSale() public view returns (uint256) {
        return supply - _tokenIds.current();
    }

    function getPrimarySalePrice() public view returns (uint256) {
        return primarySalePrice;
    }

    function getSecondaryMarkup() public view returns (uint8) {
        return secondaryMarkup;
    }

    function tokenScanned(uint256 tokenId) public onlyOwner {
        require(
            tokenStates[tokenId] != tokenState.SCANNED,
            "Token has already been scanned"
        );
        require(
            tokenStates[tokenId] != tokenState.INVALIDATED,
            "Token has been invalidated"
        );
        tokenStates[tokenId] = tokenState.SCANNED;
    }

    function tokenInvalidated(uint256 tokenId) public onlyOwner {
        tokenStates[tokenId] = tokenState.INVALIDATED;
    }

    // function mintNFTWithRoyalty(
    //     address recipient,
    //     string memory tokenURI,
    //     address royaltyReceiver,
    //     uint96 feeNumerator
    // ) public whenNotPaused onlyOwner returns (uint256) {
    //     uint256 tokenId = mintNFT(recipient, tokenURI);
    //     _setTokenRoyalty(tokenId, royaltyReceiver, feeNumerator);

    //     return tokenId;
    // }
}
