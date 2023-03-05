// contracts/BasicTicket.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./IBlockPassTicket.sol";
import "./BlockPassTicket.sol";

contract BlockPass is ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _primarySales;
    Counters.Counter private _secondarySales;
    uint256 public TAKE_RATE = 10; // 10% primary take rate
    uint256 public EO_TAKE = 100 - TAKE_RATE;
    address payable private _marketOwner;
    mapping(address => EventTicketContract) public _addressToTicketContract;
    mapping(address => mapping(uint256 => Ticket)) public _secondaryMarket;

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
        uint256 eventEndDate;
        uint256 liveDate;
        uint256 closeDate;
        uint256 supply;
        bool active;
    }

    event TicketTierListed(
        address ticketContract,
        address eventOrganizer,
        uint256 price,
        uint256 end,
        uint256 live,
        uint256 close
    );

    event TicketSold(
        address ticketContract,
        uint256 tokenId,
        address eventOrganizer,
        address buyer,
        uint256 price,
        bool isPrimary
    );

    event TokenListed(
        address ticketContract,
        uint256 tokenId,
        address seller,
        uint256 price
    );

    constructor() {
        _marketOwner = payable(msg.sender);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Withdraw function for market owner.
    function marketWithdraw(uint256 _amount) public {
        require(
            msg.sender == _marketOwner,
            "Action only allowed by market owner."
        );
        require(
            _amount < address(this).balance,
            "Withdrawal amount exceeds contract balance."
        );
        _marketOwner.transfer(_amount);
    }

    // List the ticket contract on the marketplace
    function listTicketContract(
        address _ticketContract,
        uint256 _primarySalePrice,
        uint8 _secondaryMarkup,
        address _eventOrganizer,
        uint256 _eventEndDate,
        uint256 _liveDate,
        uint256 _closeDate,
        uint256 _supply
    ) public payable nonReentrant {
        // require it to not already be listed, and caller to be the contract itself via the RBAC enforced listTicketContract function.
        require(
            ERC165Checker.supportsInterface(
                _ticketContract,
                type(IBlockPassTicket).interfaceId
            ),
            "Contract doesn't inherit IBlockPassTicket interface."
        );
        require(
            _addressToTicketContract[_ticketContract].ticketContract ==
                address(0),
            "Ticket already registerd with marketplace."
        );
        require(
            msg.sender == _ticketContract,
            "Caller does not have contract listing permissions."
        );

        _addressToTicketContract[_ticketContract] = EventTicketContract(
            _ticketContract,
            _primarySalePrice,
            _secondaryMarkup,
            payable(_eventOrganizer),
            payable(address(this)),
            _eventEndDate,
            _liveDate,
            _closeDate,
            _supply,
            true
        );

        emit TicketTierListed(
            _ticketContract,
            _eventOrganizer,
            _primarySalePrice,
            _eventEndDate,
            _liveDate,
            _closeDate
        );
    }

    // Buy a ticket
    function buyTicket(address _ticketContract) public payable nonReentrant {
        EventTicketContract storage ticketContract = _addressToTicketContract[
            _ticketContract
        ];
        require(
            ticketContract.owner != address(0),
            "Ticket contract does not exist."
        );
        require(
            msg.value == ticketContract.primarySalePrice,
            "Funds should match the sales price."
        );
        require(
            block.timestamp > ticketContract.liveDate,
            "Primary sale of these tickets have not yet started."
        );
        require(
            block.timestamp < ticketContract.closeDate,
            "Primary sale of these tickets have ended."
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
        require(
            ticketContract.owner != address(0),
            "Ticket contract does not exist."
        );
        Ticket storage ticket = _secondaryMarket[_ticketContract][_tokenId];
        require(
            ticket.owner == address(0),
            "Ticket is already listed for sale."
        );

        require(
            isPriceProtectionValid(ticketContract, _price),
            "Price set above secondary markup limit. Price increase allowed after event end date."
        );

        IERC721(_ticketContract).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        _secondaryMarket[_ticketContract][_tokenId] = Ticket(
            _ticketContract,
            payable(msg.sender),
            _price
        );

        emit TokenListed(_ticketContract, _tokenId, msg.sender, _price);
    }

    // update the sale price for a ticket in the secondary market.
    function updateTicketSalePrice(
        uint256 _newPrice,
        address _ticketContractAddr,
        uint256 _tokenId
    ) public nonReentrant {
        require(_newPrice > 0, "Price must be at least 1 wei");
        Ticket memory resaleTicket = _secondaryMarket[_ticketContractAddr][
            _tokenId
        ];
        require(
            resaleTicket.ticketContract != address(0),
            "Ticket does not exist, or is not for sale."
        );
        require(
            resaleTicket.owner == msg.sender,
            "Sending address does not own the token."
        );
        EventTicketContract storage ticketContract = _addressToTicketContract[
            _ticketContractAddr
        ];
        require(
            isPriceProtectionValid(ticketContract, _newPrice),
            "Price set above secondary markup limit. Price increase allowed after event end date."
        );

        // set the new price
        _secondaryMarket[_ticketContractAddr][_tokenId] = Ticket(
            _ticketContractAddr,
            payable(msg.sender),
            _newPrice
        );
    }

    // Cancel the resale of a ticket put on the secondary market.
    function cancelResale(address _ticketContractAddr, uint256 _tokenId) public nonReentrant {
        Ticket memory resaleTicket = _secondaryMarket[_ticketContractAddr][
            _tokenId
        ];
        require(
            resaleTicket.ticketContract != address(0),
            "Ticket does not exist, or is not for sale."
        );
        require(
            resaleTicket.owner == msg.sender,
            "Sending address does not own the token."
        );

        // transfer token back to owner.
        IERC721(_ticketContractAddr).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );

        delete _secondaryMarket[_ticketContractAddr][_tokenId];

    }

    function buySecondaryTicket(address _ticketContract, uint256 _tokenId)
        public
        payable
        nonReentrant
    {
        Ticket storage ticket = _secondaryMarket[_ticketContract][_tokenId];
        require(ticket.owner != address(0), "Ticket does not exist.");
        require(msg.value >= ticket.price, "Funds do not cover ticket cost");

        (address _receiver, uint256 _royalty) = ERC2981(_ticketContract)
            .royaltyInfo(_tokenId, ticket.price);

        // pay royalties
        payable(_receiver).transfer(_royalty);
        // pay seller
        payable(ticket.owner).transfer(ticket.price.sub(_royalty));
        // transfer ticket
        IERC721(_ticketContract).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );

        _secondarySales.increment();
        emit TicketSold(
            _ticketContract,
            _tokenId,
            _addressToTicketContract[_ticketContract].eventOrganizer,
            msg.sender,
            ticket.price,
            false
        );
        // remove ticket from secondary market
        delete _secondaryMarket[_ticketContract][_tokenId];
    }

    function isPriceProtectionValid(
        EventTicketContract memory ticketContract,
        uint256 _price
    ) private view returns (bool) {
        // disallow prices above the set secondary markup if event has not yet passed.
        if (block.timestamp <= ticketContract.eventEndDate) {
            uint8 secondaryMarkup = ticketContract.secondaryMarkup;
            uint256 primarySalePrice = ticketContract.primarySalePrice;
            if (
                _price >
                ticketContract.primarySalePrice.add(
                    primarySalePrice.div(100).mul(secondaryMarkup)
                )
            ) {
                return false;
            }
        }

        return true;
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
