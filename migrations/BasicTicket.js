const BasicTicket = artifacts.require("BasicTicket");

module.exports = function (deployer) {
  deployer.deploy(BasicTicket);
};
