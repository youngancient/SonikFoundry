// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {AirdropFactoryFacet} from "../contracts/facets/erc20facets/FactoryFacet.sol";
import {PoapFactoryFacet} from "../contracts/facets/erc721facets/PoapFactoryFacet.sol";

import "forge-std/Script.sol";

contract SoniKDeployer is Script {
    // Facets

    // AirdropFactoryFacet airdropFactoryFacet;
    PoapFactoryFacet poapFactoryFacet;

    bytes32 constant SALT_AIRDROP = keccak256("SonikDrop_AirdropFactoryFacet");
    bytes32 constant SALT_POAP = keccak256("SonikDrop_PoapFactoryFacet");

    function run() external {
        vm.startBroadcast();

        // Deploy facets
        deployFacets();

        vm.stopBroadcast();
    }

    function deployFacets() internal {
        // airdropFactoryFacet = new AirdropFactoryFacet{salt: SALT_AIRDROP}();
        // console.log("AirdropFactoryFacet deployed at:", address(airdropFactoryFacet));

        poapFactoryFacet = new PoapFactoryFacet{salt: SALT_POAP}();
        console.log("PoapFactoryFacet deployed at:", address(poapFactoryFacet));
    }
}