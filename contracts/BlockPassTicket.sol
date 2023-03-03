// contracts/BlockPassTicket.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
//This implementation of ERC721 is used so that we store the tokenURIs on chain in storage, which is what allows us to store the metadata we upload to IPFS off-chain.
// https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721URIStorage
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol"; // https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BlockPass.sol";
import "./IBlockPassTicket.sol";

abstract contract BlockPassTicket is
    IBlockPassTicket,
    ERC721URIStorage,
    ERC2981,
    AccessControl,
    Pausable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    // the wallet address of the event organizer
    address public eventOrganizer;
    // the address of the marketplace contract
    address public marketplaceContract;
    // the primary token sale price
    uint256 public primarySalePrice;
    // the max percentage a token can be marked up if resold before the event.
    uint8 public secondaryMarkup; // ex. 10 for 10%
    // the max supply of tickets that can be minted
    uint256 public supply;
    // the uri pointing to the token asset
    string public _tokenURI;
    // the state of a token
    enum tokenState {
        SOLD,
        SCANNED,
        INVALIDATED
    }
    // contract access control roles
    bytes32 public constant CONTROLLER = keccak256("CONTROLLER");
    // mapping of token ids to its state
    mapping(uint256 => tokenState) tokenStates;

    // start date of event in UTC milliseconds
    uint256 public startDate;
    // end date of the event in UTC milliseconds
    uint256 public endDate;
    // the date this ticket tier is available for purchase.
    uint256 public liveDate;
    // the date this ticket tier is closed for purchase.
    uint256 public closeDate;

    // https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721URIStorage-tokenURI-uint256-

    constructor(
        string memory _name,
        string memory _symbol,
        address _marketplaceContract,
        address _eventOrganizer,
        string memory tokenURI,
        uint256 _primarySalePrice,
        uint8 _secondaryMarkup,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _liveDate,
        uint256 _closeDate,
        uint256 _supply
    ) ERC721(_name, _symbol) {
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
        require(
            _closeDate >= block.timestamp,
            "Ticket tier close date can't be in the past"
        );
        require(
            _liveDate <= _closeDate,
            "Invalid live and close date relationship."
        );
        require(_supply > 0, "Supply must be greater than zero");
        require(bytes(tokenURI).length != 0, "Token URI must not be empty");
        _grantRole(CONTROLLER, msg.sender);
        // set event organizer royalty to be 10%
        _setDefaultRoyalty(_eventOrganizer, 1000);
        marketplaceContract = _marketplaceContract;
        eventOrganizer = _eventOrganizer;
        _tokenURI = tokenURI;
        primarySalePrice = _primarySalePrice;
        secondaryMarkup = _secondaryMarkup;
        startDate = _startDate;
        endDate = _endDate;
        liveDate = _liveDate;
        closeDate = _closeDate;
        supply = _supply;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IBlockPassTicket).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // override the _burn function so that it also clears the royalty information for a burnt token
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    // burn function for external accounts.
    function burnNFT(uint256 tokenId) public override {
        _burn(tokenId);
    }

    function mintNFT(address recipient)
        public
        override
        whenNotPaused
        onlyRole(CONTROLLER)
        returns (uint256)
    {
        require(
            block.timestamp <= closeDate,
            "Unable to mint tokens after the ticket tier close date has passed."
        );
        require(_tokenIds.current() < supply, "Ticket supply sold out");
        require(
            recipient != address(0),
            "Recipient can't be the zero address."
        );
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(recipient, newItemId);
        tokenStates[newItemId] = tokenState.SOLD;
        _setTokenURI(newItemId, _tokenURI);
        _setApprovalForAll(recipient, marketplaceContract, true);
        emit NFTMinted(newItemId);

        return newItemId;
    }

    function setEventOrganizer(address newOrganizer)
        public
        override
        onlyRole(CONTROLLER)
    {
        eventOrganizer = newOrganizer;
    }

    function setMarketplaceContract(address newMarketplace)
        public
        override
        onlyRole(CONTROLLER)
    {
        marketplaceContract = newMarketplace;
    }

    function increaseTicketSupply(uint256 additionalSupply)
        public
        override
        onlyRole(CONTROLLER)
        returns (uint256)
    {
        supply += additionalSupply;
        return supply;
    }

    function getTotalTicketsForSale() public view override returns (uint256) {
        return supply - _tokenIds.current();
    }

    function setPrimarySalePrice(uint256 newPrice)
        public
        override
        onlyRole(CONTROLLER)
    {
        primarySalePrice = newPrice;
    }

    function setSecondaryMarkup(uint8 newMarkup) public override {
        secondaryMarkup = newMarkup;
    }

    function tokenScanned(uint256 tokenId)
        public
        override
        onlyRole(CONTROLLER)
    {
        require(
            tokenStates[tokenId] != tokenState.SCANNED,
            "Token has already been scanned"
        );
        require(
            tokenStates[tokenId] != tokenState.INVALIDATED,
            "Token has been invalidated"
        );
        require(_tokenIds.current() >= tokenId, "Token not yet minted.");
        tokenStates[tokenId] = tokenState.SCANNED;
    }

    function tokenInvalidated(uint256 tokenId)
        public
        override
        onlyRole(CONTROLLER)
    {
        require(_tokenIds.current() >= tokenId, "Token not yet minted.");
        tokenStates[tokenId] = tokenState.INVALIDATED;
    }

    function listTicketContract() public override onlyRole(CONTROLLER) {
        BlockPass(marketplaceContract).listTicketContract(
            address(this),
            primarySalePrice,
            secondaryMarkup,
            eventOrganizer,
            startDate,
            endDate,
            supply
        );

        // grant controller role of the contract to the marketplace.
        _grantRole(CONTROLLER, marketplaceContract);
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
