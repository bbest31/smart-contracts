// contracts/IBlockPassTicket.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

interface IBlockPassTicket {
    /**
     * @dev Emitted when a token is minted.
     */
    event NFTMinted(uint256);
    /**
     * @dev Emitted when a token is scanned
     */
    event TokenScanned(uint256);
    /**
     * @dev Emitted when a token is invalidated.
     */
    event TokenInvalidated(uint256);

    /**
     * @dev Burn function for external accounts.
     */
    function burnNFT(uint256 tokenId) external;

    /**
     * @dev  Mints a token and transfers it to the `recipient`.
     *
     * Requirments:
     *
     * - `recipient1 can't be zero address.
     * - `endDate` can't be in the past.
     * - `_tokenIds` current number can't be >= `supply`.
     */
    function mintNFT(address recipient) external returns (uint256);

    /**
     * @dev Sets a new address as the event organizer.
     */
    function setEventOrganizer(address newOrganizer) external;

    /**
     * @dev Sets a new address referring to the marketplace contract.
     */
    function setMarketplaceContract(address newMaretplace) external;

    /**
     * @dev Increases the max supply of mintable tokens by `additionalSupply`.
     */
    function increaseTicketSupply(
        uint256 additionalSupply
    ) external returns (uint256);

    /**
     * @dev Returns the total tickets still available for sale.
     */
    function getTotalTicketsForSale() external view returns (uint256);

    /**
     * @dev Sets a new primary sale price.
     */
    function setPrimarySalePrice(uint256 newPrice) external;

    /**
     * @dev Sets a new secondary markup price.
     */
    function setSecondaryMarkup(uint8 newMarkup) external;

    /**
     * @dev Sets the associated state with the given token to be `SCANNED`.
     *
     * Requirements:
     *
     * - `tokenId` must not already be scanned.
     * - `tokenId` must not already be invalidated.
     * - `tokenId` must have been minted
     */
    function tokenScanned(uint256 tokenId) external;

    /**
     * @dev Invalidate a token.
     *
     * Requirements:
     * - `tokenId` must be minted.
     */
    function tokenInvalidated(uint256 tokenId) external;

    /**
     * @dev Register this ticket tier with the marketplace contract, and give the marketplace contract
     * access control over protected functions.
     */
    function listTicketContract() external;

    /**
     * @dev Sets the closeDate of the ticket tier.
     */
    function setCloseDate(uint256 newCloseDate) external;
}