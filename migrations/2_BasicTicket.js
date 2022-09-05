const BasicTicket = artifacts.require("BasicTicket");

module.exports = function (
  deployer,
  network,
  eventOrgAddress,
  tokenURI,
  primarySalePrice,
  secondaryMarkup
) {
  if (network == "development") {
    deployer.deploy(
      BasicTicket,
      "0x31bc80aF9F05Ea398Ada5eCE0e9087Ab76e3b9ac",
      "https://ibb.co/7yBDfqk",
      100,
      0
    );
  } else {
    deployer.deploy(
      BasicTicket,
      eventOrgAddress,
      tokenURI,
      primarySalePrice,
      secondaryMarkup
    );
  }
};
