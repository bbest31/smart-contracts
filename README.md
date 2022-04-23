# Smart Contracts

This repo holds all of the BlockPass smart contract templates that are used to administer tickets and hold util functions for contracts.

The majority of these contracts will be based off templates from [OpenZeppelin](https://docs.openzeppelin.com/contracts/4.x/).

Here is a link to the [ERC-721 NFT Standard](https://eips.ethereum.org/EIPS/eip-721)

### Requirements
* npm

## Instructions


### VS Code using Truffle (Recommended)

* `npm install -g truffle` (may need to run command prompt as administrator to perform).
* `npm install` to retrieve all used packages.
* To compile contracts run `truffle compile`. 
* To test run `truffle test ./test/TestContractName.sol`
* To deploy a development blockchain run `truffle develop`.
* to deploy contracts to development blockchain run `migrate` within the Truffle Develop prompt.
