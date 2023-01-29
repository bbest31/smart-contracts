// contracts/BasicTicket.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BlockPassTicket.sol";

contract BlockPass is ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _primarySales;
    Counters.Counter private _secondarySales;
    uint256 public TAKE_RATE = 10; // 10% primary take rate
    uint256 public EO_TAKE = 100 - TAKE_RATE;
    address payable private _marketOwner;
    mapping(address => EventTicketContract) private _addressToTicketContract;
    mapping(address => mapping(uint256 => Ticket)) private _secondaryMarket;

    struct Ticket {
        address ticketContract;
        address owner;
        uint256 price;
    }

    struct EventTicketContract {
        address ticketContract;
        uint256 primarySalePrice;
        uint8 secondaryMarkup;
        address payable eventOrganizer;
        address payable owner;
        uint256 startDate;
        uint256 endDate;
        uint256 supply;
        bool active;
    }

    event EventTicketListed(
        address ticketContract,
        address eventOrganizer,
        uint256 price,
        uint256 start,
        uint256 end
    );

    event TicketSold(
        address ticketContract,
        uint256 tokenId,
        address eventOrganizer,
        address buyer,
        uint256 price,
        bool isPrimary
    );

    event TicketListed(
        address ticketContract,
        uint256 tokenId,
        address seller,
        uint256 price
    );

    constructor() {
        _marketOwner = payable(msg.sender);
    }

    // List the ticket contract on the marketplace
    function listTicketContract(
        address _ticketContract,
        uint256 _primarySalePrice,
        uint8 _secondaryMarkup,
        address _eventOrganizer,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _supply
    ) public payable nonReentrant {
        require(
            msg.sender == Ownable(_ticketContract).owner(),
            "Listing can only be done by the event contract owner"
        );
        _addressToTicketContract[_ticketContract] = EventTicketContract(
            _ticketContract,
            _primarySalePrice,
            _secondaryMarkup,
            payable(_eventOrganizer),
            payable(address(this)),
            _startDate,
            _endDate,
            _supply,
            true
        );

        // transfer ownership of the contract to the marketplace.
        Ownable(_ticketContract).transferOwnership(address(this));

        emit EventTicketListed(
            _ticketContract,
            _eventOrganizer,
            _primarySalePrice,
            _startDate,
            _endDate
        );
    }

    // Buy a ticket
    function buyTicket(address _ticketContract) public payable nonReentrant {
        EventTicketContract storage ticketContract = _addressToTicketContract[
            _ticketContract
        ];
        require(
            msg.value >= ticketContract.primarySalePrice,
            "Not enough funds to cover the sale price"
        );
        require(
            ticketContract.active != false,
            "Ticket contract is not active"
        );

        address payable buyer = payable(msg.sender);
        payable(ticketContract.eventOrganizer).transfer(
            ticketContract.primarySalePrice.div(100).mul(EO_TAKE)
        );
        uint256 tokenId = BlockPassTicket(_ticketContract).mintNFT(buyer);
        _marketOwner.transfer(
            ticketContract.primarySalePrice.div(100).mul(TAKE_RATE)
        );

        _primarySales.increment();
        emit TicketSold(
            _ticketContract,
            tokenId,
            ticketContract.eventOrganizer,
            buyer,
            msg.value,
            true
        );

        //if the last ticket is sold then mark as not active.
        if (tokenId == ticketContract.supply) {
            ticketContract.active = false;
            _addressToTicketContract[_ticketContract] = ticketContract;
        }
    }

    // List an individual ticket purchased from the marketplace for resale
    function resellTicket(
        address _ticketContract,
        uint256 _tokenId,
        uint256 _price
    ) public payable nonReentrant {
        require(_price > 0, "Price must be at least 1 wei");

        EventTicketContract storage ticketContract = _addressToTicketContract[
            _ticketContract
        ];
        // disallow prices above the set secondary markup if event has not yet passed.
        if (block.timestamp <= ticketContract.endDate) {
            uint8 secondaryMarkup = ticketContract.secondaryMarkup;
            uint256 primarySalePrice = ticketContract.primarySalePrice;
            require(
                _price <=
                    ticketContract.primarySalePrice.add(
                        primarySalePrice.mul(secondaryMarkup)
                    )
            );
        }

        IERC721(_ticketContract).transferFrom(msg.sender, address(this), _tokenId);

        _secondaryMarket[_ticketContract][_tokenId] = Ticket(
            _ticketContract,
            payable(msg.sender),
            _price
        );

        emit TicketListed(_ticketContract, _tokenId, msg.sender, _price);
    }

    function buySecondaryTicket(address _ticketContract, uint256 _tokenId)
        public
        payable
        nonReentrant
    {
        Ticket storage ticket = _secondaryMarket[_ticketContract][_tokenId];
        require(msg.value >= ticket.price, "Funds do not cover ticket cost");

        (address _receiver, uint256 _royalty) = ERC2981(_ticketContract)
            .royaltyInfo(_tokenId, ticket.price);

        // pay royalties
        payable(_receiver).transfer(_royalty);
        // pay seller
        payable(ticket.owner).transfer(ticket.price.sub(_royalty));
        // transfer ticket
        IERC721(_ticketContract).transferFrom(ticket.owner, msg.sender, _tokenId);

        _secondarySales.increment();
        emit TicketSold(
            _ticketContract,
            _tokenId,
            _addressToTicketContract[_ticketContract].eventOrganizer,
            msg.sender,
            ticket.price,
            false
        );
    }

    //==============================Attendee/Query Functions=====================================

    //TODO getListedTicketContracts

    //TODO getListedSecondaryMarketTickets

    // function getListedNfts() public view returns (NFT[] memory) {
    //     uint256 nftCount = _nftCount.current();
    //     uint256 unsoldNftsCount = nftCount - _primarySales.current();

    //     NFT[] memory nfts = new NFT[](unsoldNftsCount);
    //     uint256 nftsIndex = 0;
    //     for (uint256 i = 0; i < nftCount; i++) {
    //         if (_idToNFT[i + 1].listed) {
    //             nfts[nftsIndex] = _idToNFT[i + 1];
    //             nftsIndex++;
    //         }
    //     }
    //     return nfts;
    // }

    //TODO change to get my tickets
    // function getMyNfts() public view returns (NFT[] memory) {
    //     uint256 nftCount = _nftCount.current();
    //     uint256 myNftCount = 0;
    //     for (uint256 i = 0; i < nftCount; i++) {
    //         if (_idToNFT[i + 1].owner == msg.sender) {
    //             myNftCount++;
    //         }
    //     }

    //     NFT[] memory nfts = new NFT[](myNftCount);
    //     uint256 nftsIndex = 0;
    //     for (uint256 i = 0; i < nftCount; i++) {
    //         if (_idToNFT[i + 1].owner == msg.sender) {
    //             nfts[nftsIndex] = _idToNFT[i + 1];
    //             nftsIndex++;
    //         }
    //     }
    //     return nfts;
    // }

    // TODO: getMyListedSecondaryMarketTickets
    // function getMyListedNfts() public view returns (NFT[] memory) {
    //     uint256 nftCount = _nftCount.current();
    //     uint256 myListedNftCount = 0;
    //     for (uint256 i = 0; i < nftCount; i++) {
    //         if (
    //             _idToNFT[i + 1].seller == msg.sender && _idToNFT[i + 1].listed
    //         ) {
    //             myListedNftCount++;
    //         }
    //     }

    //     NFT[] memory nfts = new NFT[](myListedNftCount);
    //     uint256 nftsIndex = 0;
    //     for (uint256 i = 0; i < nftCount; i++) {
    //         if (
    //             _idToNFT[i + 1].seller == msg.sender && _idToNFT[i + 1].listed
    //         ) {
    //             nfts[nftsIndex] = _idToNFT[i + 1];
    //             nftsIndex++;
    //         }
    //     }
    //     return nfts;
    // }
}
