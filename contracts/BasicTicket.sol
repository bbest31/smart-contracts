// contracts/BasicTicket.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
//This implementation of ERC721 is used so that we store the tokenURIs on chain in storage, which is what allows us to store the metadata we upload to IPFS off-chain.
// https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721URIStorage
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
import "@openzeppelin/contracts/utils/Counters.sol";

contract BasicTicket is ERC721URIStorage, ERC2981, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    event NFTMinted(uint256);
    // TODO: event for scanning of token
    // TODO: event for resale
    // TODO: event for invalidated
    // the wallet address of the event organizer
    address eventOrganizer;
    // the primary token sale price
    uint256 primarySalePrice;
    // the max percentage a token can be marked up if resold before the event.
    uint8 secondaryMarkup;
    // the uri pointing to the token asset
    string _tokenURI;
    // the state of a token
    enum tokenState {
        SOLD,
        SCANNED,
        RESOLD,
        INVALIDATED
    }
    // mapping of token ids to its state
    mapping(uint256 => tokenState) tokenStates;

    // TODO: check if block.timestamp is close enough to IRL
    // start date of event in UTC seconds
    uint256 startDate;
    // end date of the event in UTC seconds
    uint256 endDate;

    // https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721URIStorage-tokenURI-uint256-

    constructor(
        address _eventOrganizer,
        string memory tokenURI,
        uint256 _primarySalePrice,
        uint8 _secondaryMarkup
    ) ERC721("BasicTicket", "BPT") {
        require(
            _eventOrganizer != address(0),
            "Event organizer can't be the zero address"
        );
        // set event organizer royalty to be 10%
        _setDefaultRoyalty(_eventOrganizer, 1000);
        eventOrganizer = _eventOrganizer;
        _tokenURI = tokenURI;
        primarySalePrice = _primarySalePrice;
        secondaryMarkup = _secondaryMarkup;
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

    function getPrimarySalePrice() public view returns (uint256) {
        return primarySalePrice;
    }

    function getSecondaryMarkup() public view returns (uint8) {
        return secondaryMarkup;
    }

    // TODO: function to set token to SCANNED state;
    // TODO: function to set token to RESOLD state;
    // TODO: function to set token to INVALIDATED state;

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
