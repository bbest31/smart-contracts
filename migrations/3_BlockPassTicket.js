const BlockPassTicket = artifacts.require("BlockPassTicket");

module.exports = function (
  deployer,
  network,
  name,
  symbol,
  marketplaceContract,
  eventOrgAddress,
  tokenURI,
  primarySalePrice,
  secondaryMarkup,
  feeNumerator,
  eventEndDate,
  liveDate,
  closeDate,
  supply
) {
  if (network == "development") {
    let date = new Date();
    let start = date.valueOf();
    date.setDate(date.getDate() + 3); // 3 days ahead of the start
    let end = date.valueOf();

    deployer.deploy(
      TicketExample,
      name,
      symbol,
      marketplaceContract,
      eventOrgAddress,
      "https://i.ibb.co/dKXvTRm/Block-Pass-Logo.png",
      primarySalePrice,
      secondaryMarkup,
      feeNumerator,
      end,
      start,
      end,
      supply
    );
  } else {
    deployer.deploy(
      BlockPassTicket,
      name,
      symbol,
      marketplaceContract,
      eventOrgAddress,
      tokenURI,
      primarySalePrice,
      secondaryMarkup,
      feeNumerator,
      eventEndDate,
      liveDate,
      closeDate,
      supply
    );
  }
};
