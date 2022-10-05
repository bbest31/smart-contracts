const BlockPassTicket = artifacts.require("BlockPassTicket");

module.exports = function (
  deployer,
  network,
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
    let start = date.getUTCMilliseconds();
    date.setDate(date.getDate() + 3); // 3 days ahead of the start
    let end = date.getUTCMilliseconds();

    deployer.deploy(
      BlockPassTicket,
      "0x31bc80aF9F05Ea398Ada5eCE0e9087Ab76e3b9ac",
      "https://ibb.co/7yBDfqk",
      100,
      0,
      start,
      end,
      10
    );
  } else {
    deployer.deploy(
      BlockPassTicket,
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
