// contracts/BlockPassTicket.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "./ABlockPassTicket.sol";

contract BlockPassTicket is ABlockPassTicket, ERC165Storage {
    struct TicketInformation {
        string tokenURI;
        uint256 _primarySalePrice;
        uint96 _secondaryMarkup;
        uint96 _feeNumerator;
        uint256 _liveDate;
        uint256 _closeDate;
        uint256 _supply;
    }

    struct EventInformation {
        address _marketplaceContract;
        address _eventOrganizer;
        uint256 _eventEndDate;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        TicketInformation memory ticketInfo,
        EventInformation memory eventInfo
    )
        ABlockPassTicket(
            _name,
            _symbol,
            eventInfo._marketplaceContract,
            eventInfo._eventOrganizer,
            ticketInfo.tokenURI,
            ticketInfo._primarySalePrice,
            ticketInfo._secondaryMarkup,
            ticketInfo._feeNumerator,
            eventInfo._eventEndDate,
            ticketInfo._liveDate,
            ticketInfo._closeDate,
            ticketInfo._supply
        )
    {}

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ABlockPassTicket, ERC165Storage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
