const BlockPassTicket = artifacts.require("BlockPassTicket");

module.exports = function (
  deployer,
  network,
  marketplaceContract,
  eventOrgAddress,
  tokenURI,
  primarySalePrice,
  secondaryMarkup,
  startDate,
  endDate,
  supply
) {
  if (network == "development") {
    let date = new Date();
    let start = date.valueOf();
    date.setDate(date.getDate() + 3); // 3 days ahead of the start
    let end = date.valueOf();

    deployer.deploy(
      BlockPassTicket,
      marketplaceContract,
      eventOrgAddress,
      "https://ibb.co/7yBDfqk",
      primarySalePrice,
      secondaryMarkup,
      start,
      end,
      supply
    );
  } else {
    deployer.deploy(
      BlockPassTicket,
      marketplaceContract,
      eventOrgAddress,
      tokenURI,
      primarySalePrice,
      secondaryMarkup,
      startDate,
      endDate,
      supply
    );
  }
};
