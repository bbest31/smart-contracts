const BasicTicket = artifacts.require("BasicTicket");

module.exports = function (
  deployer,
  network,
  eventOrgAddress,
  tokenURI,
  primarySalePrice,
  secondaryMarkup,
  startDate,
  endDate
) {
  if (network == "development") {
    let start = new Date();
    let end = start.setDate(start.getDate() + 3); // 3 days ahead of the start
    
    deployer.deploy(
      BasicTicket,
      "0x31bc80aF9F05Ea398Ada5eCE0e9087Ab76e3b9ac",
      "https://ibb.co/7yBDfqk",
      100,
      0,
      start.getUTCMilliseconds(),
      end
    );
  } else {
    deployer.deploy(
      BasicTicket,
      eventOrgAddress,
      tokenURI,
      primarySalePrice,
      secondaryMarkup,
      startDate,
      endDate
    );
  }
};
