// contracts/BasicTicket.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BasicTicket is ERC721URIStorage, ERC2981, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("BasicTicket", "BPT") {
        // set contract owner royalty to be 1%
        _setDefaultRoyalty(msg.sender, 100);
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
    // TODO: determine if we want this functionality
    function burnNFT(uint256 tokenId) public {
        _burn(tokenId);
    }

    function mintNFT(address recipient, string memory tokenURI)
        public
        whenNotPaused
        onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function mintNFTWithRoyalty(
        address recipient,
        string memory tokenURI,
        address royaltyReceiver,
        uint96 feeNumerator
    ) public whenNotPaused onlyOwner returns (uint256) {
        uint256 tokenId = mintNFT(recipient, tokenURI);
        _setTokenRoyalty(tokenId, royaltyReceiver, feeNumerator);

        return tokenId;
    }
}
