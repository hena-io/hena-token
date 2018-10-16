var Hena = artifacts.require("./Hena.sol");

module.exports = async function(deployer) {
  await deployer.deploy(Hena);
};
