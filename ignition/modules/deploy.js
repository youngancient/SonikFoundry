const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const DeployModule = buildModule("DeployModule", (m) => {
    // Deploy AirdropFactoryFacet
    const airdropFactoryFacet = m.contract("AirdropFactoryFacet");

    // Deploy PoapFactoryFacet
    const poapFactoryFacet = m.contract("PoapFactoryFacet");

    return { airdropFactoryFacet, poapFactoryFacet };
});

module.exports = DeployModule;
