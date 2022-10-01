# Smart Contracts

This repo holds all of the BlockPass smart contract templates that are used to administer tickets and hold util functions for contracts.

The majority of these contracts will be based off templates from [OpenZeppelin](https://docs.openzeppelin.com/contracts/4.x/).

Here is a link to the [ERC-721 NFT Standard](https://eips.ethereum.org/EIPS/eip-721)

### Requirements
* npm

## Instructions
* Follow [Smart Contract Development Environment](https://www.notion.so/Smart-Contract-Development-Environment-7b72d463198342ff87779840b47666b4) for steps on setup.

### Minting Tickets
1. Wallet 1 should be used to deploy the ticket contract.
2. A second wallet Wallet 2 can be set as the event organizer.
3. Only Wallet 1 can be used to call the mintNFT function.
4. Wallet 1 can't be the recipient of the mintNFT.

## References
* [How to build an NFT markeplace dApp on Ethereum or Optimism](https://trufflesuite.com/guides/nft-marketplace/#overview)