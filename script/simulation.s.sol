// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {AirdropFactoryFacet} from "../src/facets/erc20facets/FactoryFacet.sol";
import {PoapFactoryFacet} from "../src/facets/erc721facets/PoapFactoryFacet.sol";

import {SonikPoapFacet} from "../src/facets/erc721facets/SonikPoapFacet.sol";
import {GetProof} from "../test/helpers/GetProof.sol";

import "forge-std/Script.sol";

contract Runner is Script {
    // Facets

    PoapFactoryFacet poapFactoryFacet = PoapFactoryFacet(0x5A4b4b8Bed1087D6F2De87177341ea27F06Bdb24);

    bytes32 merkleRoot = 0xdd3f06f7a8978c364e784646d64988d6b1f8dc1f487888f342729479a1892288;
    bytes32 hash = keccak256("claimed sonik droppppppppppp");
    string baseURI = "https://ipfs.io/ipfs/bafkreidolt4hcw7zbo2cp745g3zyommfz4e43g4pgdevu4ade2ujp2vgma";

    function run() external {
        vm.startBroadcast();

        // Deploy facets
        simulate();

        vm.stopBroadcast();
    }

    function simulate() internal {
        poapFactoryFacet.createSonikPoap("GOJODEV", "GJD", baseURI, merkleRoot, 5);
        address[] memory thi = poapFactoryFacet.getOwnerSonikPoapClones(msg.sender);
        SonikPoapFacet here = SonikPoapFacet(thi[0]);
        bytes32[] memory proof = new bytes32[](3);

        proof[0] = bytes32(0x4e2ef3f4d279d23ce0933035d8c8fb3ce41acb03aa29a326c527a6c76b912f6e);
        proof[1] = bytes32(0x64db0af4e3097c2974bf8abb17133c058f2076a7074b7aecfa02f9a04f6ccfa0);
        proof[2] = bytes32(0x5a8ead40cd9687835259cd89e45e2781d13c6ba02e8b0a08f1be6d3f47f69f74);

        uint256 privateKey = vm.envUint("private_key");
        here.claimAirdrop(proof, hash, get_signa(privateKey));
        console.log("PoapFactoryFacet deployed at:", here.ownerOf(0));
    }

    function get_signa(uint256 key) internal returns (bytes memory signature) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
        signature = abi.encodePacked(r, s, v);
    }
}
