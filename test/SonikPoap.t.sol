// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {SonikPoapFacet} from "../src/facets/erc721facets/SonikPoapFacet.sol";
import {GetProof} from "./helpers/GetProof.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is ERC721 {
    constructor() ERC721("requiredNFT", "rNFT") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract SonikPoapFacetTest is GetProof {
    SonikPoapFacet sonikPoapFacet;
    TestERC721 testERC721;
    address user1;
    uint256 keyUser1;
    address user2;
    uint256 keyUser2;
    address badUser;
    uint256 keybadUser;
    address owner;
    bytes32 merkleRoot = 0xb7e09bf66d126c65602696df7f0526fd503a159828d1f8cef4959baca1512160;
    bytes32 hash = keccak256("claimed sonik droppppppppppp");
    string baseURI = "https://sonik.com/";

    function setUp() public {
        owner = msg.sender;
        sonikPoapFacet =
            new SonikPoapFacet("TESTNFT", "TNFT", baseURI, msg.sender, merkleRoot, address(0), 0, 10, false);
        testERC721 = new TestERC721();
        (user1, keyUser1) = makeAddrAndKey("user1");
        (user2, keyUser2) = makeAddrAndKey("user2");
        (badUser, keybadUser) = makeAddrAndKey("badUser");
    }

    function test_hasAidropTimeEnded() public {
        // by default the airdropEND time is  block.timestamp (deployment time) if it is not time locked
        //  the airdrop is not time locked by default
        vm.warp(block.timestamp + 1);
        assertEq(sonikPoapFacet.hasAirdropTimeEnded(), true);
    }

    function test_hasAidropTimeEndedWithTimeLock() public {
        vm.prank(owner);
        sonikPoapFacet.updateClaimTime(1 days);
        assertEq(sonikPoapFacet.hasAirdropTimeEnded(), false);
    }

    function test_hasAidropTimeEndedWithTimeLockTrue() public {
        vm.prank(owner);
        sonikPoapFacet.updateClaimTime(1 days);

        vm.warp(block.timestamp + 2 days);
        assertEq(sonikPoapFacet.hasAirdropTimeEnded(), true);
    }

    function test_checkEligibility() public {
        bytes32[] memory proof = getProofPoap(user1);
        vm.prank(user1);
        assertEq(sonikPoapFacet.checkEligibility(proof), true);
    }

    function test_checkEligibility_wrong_proof() public {
        bytes32[] memory proof = getProofPoap(user2);

        // using user 1 proof to check user2 eligitbity
        vm.prank(user1);
        assertEq(sonikPoapFacet.checkEligibility(proof), false);
    }

    //// Owned   functions

    function test_updateClaimTime() public {
        vm.prank(owner);
        sonikPoapFacet.updateClaimTime(1 days);
        assertEq(sonikPoapFacet.isTimeLocked(), true);
        assertEq(sonikPoapFacet.airdropEndTime(), block.timestamp + 1 days);
    }

    function test_updateClaimTime_notOwner() public {
        vm.startPrank(user1);

        vm.expectRevert(abi.encodeWithSignature("UnAuthorizedFunctionCall()"));

        sonikPoapFacet.updateClaimTime(1 days);
        assertEq(sonikPoapFacet.isTimeLocked(), false);

        vm.stopPrank();
    }

    function test_toggleNftRequirement() public {
        vm.prank(owner);
        sonikPoapFacet.toggleNftRequirement();
        assertEq(sonikPoapFacet.isNftRequired(), true);
    }

    //// public/ external  view functions

    function test_claimAirdropNFT() public {
        bytes32[] memory proof = getProofPoap(user1);

        bytes memory signature = get_signa(keyUser1);

        vm.startPrank(user1);
        sonikPoapFacet.claimAirdrop(proof, hash, signature);
        vm.stopPrank();
        assert(sonikPoapFacet.balanceOf(user1) > 0);
    }

    function test_claimAirdropNFT_notEligible() public {
        bytes32[] memory proof = getProofPoap(badUser);
        bytes memory signature = get_signa(keybadUser);
        vm.startPrank(badUser);
        vm.expectRevert(abi.encodeWithSignature("InvalidClaim()"));
        sonikPoapFacet.claimAirdrop(proof, hash, signature);
        vm.stopPrank();
    }

    function test_claimAirdropNFT_alreadyClaimed() public {
        bytes32[] memory proof = getProofPoap(user1);
        bytes memory signature = get_signa(keyUser1);
        vm.startPrank(user1);
        sonikPoapFacet.claimAirdrop(proof, hash, signature);
        vm.expectRevert(abi.encodeWithSignature("InvalidClaim()"));
        sonikPoapFacet.claimAirdrop(proof, hash, signature);
        vm.stopPrank();
    }

    function get_signa(uint256 key) public returns (bytes memory signature) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
        signature = abi.encodePacked(r, s, v);
    }

    // function test_claimAirdropNFT_with_updateClaimersNumber() public {
    //     vm.prank(owner);
    //     sonikPoapFacet.updateClaimersNumber(1);

    //     bytes32[] memory proof = getProofPoap(user1);
    //     bytes32[] memory proof2 = getProofPoap(user2);

    //     bytes memory signature = get_signa(keyUser1);
    //     bytes memory signature2 = get_signa(keyUser2);

    //     vm.prank(user1);
    //     sonikPoapFacet.claimAirdrop(proof, hash, signature);

    //     vm.expectRevert(abi.encodeWithSignature("TotalClaimersExceeded()"));
    //     vm.prank(user2);
    //     sonikPoapFacet.claimAirdrop(proof2, hash, signature2);
    // }

    function test_claimAirdropNFT_with_nft_requirement_on() public {
        vm.prank(owner);
        sonikPoapFacet.updateNftRequirement(address(testERC721));
        testERC721.mint(user2, 1);

        bytes32[] memory proof = getProofPoap(user2);

        bytes memory signature = get_signa(keyUser2);
        vm.startPrank(user2);

        sonikPoapFacet.claimAirdrop(proof, hash, signature);

        vm.stopPrank();
    }

    function test_claimAirdropNFT_with_nft_requirement_on__but_no_nft() public {
        vm.prank(owner);
        sonikPoapFacet.updateNftRequirement(address(testERC721));

        bytes32[] memory proof = getProofPoap(user2);

        bytes memory signature = get_signa(keyUser2);
        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSignature("NFTNotFound()"));
        sonikPoapFacet.claimAirdrop(proof, hash, signature);
        vm.stopPrank();
    }

    function test_claimAirdropNFT_with_time_lock_on() public {
        vm.prank(owner);
        sonikPoapFacet.updateClaimTime(1 days);
        bytes32[] memory proof = getProofPoap(user1);
        bytes memory signature = get_signa(keyUser1);
        vm.startPrank(user1);
        vm.warp(2 days);
        vm.expectRevert(abi.encodeWithSignature("AirdropClaimEnded()"));
        sonikPoapFacet.claimAirdrop(proof, hash, signature);
        vm.stopPrank();
    }
}
