// contracts/GeneralAdmissionExample.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "./BlockPassTicket.sol";

contract TicketExample is BlockPassTicket, ERC165Storage {
    constructor(
        string memory _name,
        string memory _symbol,
        address _marketplaceContract,
        address _eventOrganizer,
        string memory tokenURI,
        uint256 _primarySalePrice,
        uint8 _secondaryMarkup,
        uint96 _feeNumerator,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _liveDate,
        uint256 _closeDate,
        uint256 _supply
    )
        BlockPassTicket(
            _name,
            _symbol,
            _marketplaceContract,
            _eventOrganizer,
            tokenURI,
            _primarySalePrice,
            _secondaryMarkup,
            _feeNumerator,
            _startDate,
            _endDate,
            _liveDate,
            _closeDate,
            _supply
        )
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BlockPassTicket, ERC165Storage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
