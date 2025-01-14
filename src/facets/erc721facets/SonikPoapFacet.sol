// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC721} from "../../interfaces/IERC721.sol";
import {MerkleProof} from "../../libraries/MerkleProof.sol";
import {Errors, Events, IERC721Errors, ERC721Utils} from "../../libraries/Utils.sol";
import {ECDSA} from "../../libraries/ECDSA.sol";
import {Strings} from "../../libraries/utils/Strings.sol";

import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title SonikPoapFacet
/// @author Sonik
/// @notice This contract implements a NFT DROP with merkle proof verification
/// @dev Extends ERC721URIStorage for NFT functionality with metadata support

contract SonikPoapFacet is ERC721URIStorage {
    using Strings for uint256;
    /*====================    Variable  ====================*/

    bytes32 public immutable merkleRoot;
     uint256 public immutable creationTime;
    bool public isNftRequired;
    bool public isTimeLocked;

    address internal nftAddress;
    address internal immutable owner;
    uint256 public airdropEndTime;

    uint256 public totalNoOfClaimers;
    uint256 totalNoOfClaimed;
    uint256 index;
   
    string internal baseURI;

    mapping(address => bool) hasUserClaimedAirdrop;

    /// @notice Initializes the POAP contract with required parameters
    /// @param _name Name of the POAP token
    /// @param _symbol Symbol of the POAP token
    /// @param _baseURI Base URI for token metadata
    /// @param _owner Address of the contract owner
    /// @param _merkleRoot Merkle root for eligibility verification
    /// @param _nftAddress Address of required NFT for claiming (if any)
    /// @param _claimTime Duration for which claims are allowed
    /// @param _noOfClaimers Maximum number of allowed claims
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _owner,
        bytes32 _merkleRoot,
        address _nftAddress,
        uint256 _claimTime,
        uint256 _noOfClaimers
    ) ERC721(_name, _symbol) {
        owner = _owner;
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
        owner = _owner;

        creationTime = block.timestamp;
        nftAddress = _nftAddress;
        isNftRequired = _nftAddress != address(0);

        totalNoOfClaimers = _noOfClaimers;

        isTimeLocked = _claimTime != 0;

        if (_claimTime == 0){
        airdropEndTime = 0;
        }
        airdropEndTime = block.timestamp + _claimTime;
    }

    /// @notice Validates that the provided address is not zero
    /// @param _user Address to validate
    function sanityCheck(address _user) internal pure {
        if (_user == address(0)) {
            revert Errors.ZeroAddressDetected();
        }
    }

    /// @notice Ensures caller is the contract owner
    /// @dev Reverts if caller is not the owner
    function onlyOwner() internal view {
        if (msg.sender != owner) {
            revert Errors.UnAuthorizedFunctionCall();
        }
    }

    /// @notice Checks if the airdrop claiming period has ended
    /// @return bool True if airdrop time has ended, false otherwise
    function hasAirdropTimeEnded() public view returns (bool) {
        if (!isTimeLocked) {
            return false;
        }
        return block.timestamp > airdropEndTime;
    }

    /// @notice Verifies if caller is eligible for claiming the airdrop
    /// @param _merkleProof Merkle proof to verify eligibility
    /// @return bool True if caller is eligible, false otherwise
    function checkEligibility(bytes32[] calldata _merkleProof) public view returns (bool) {
        if (hasUserClaimedAirdrop[msg.sender]) {
            return false;
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));

        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /// @notice Claims airdrop for eligible users
    /// @param _merkleProof Merkle proof for eligibility verification
    /// @param digest Message digest for signature verification
    /// @param signature User's signature
    function claimAirdrop(bytes32[] calldata _merkleProof, bytes32 digest, bytes memory signature) external {
        if (isNftRequired) {
            claimAirdrop(_merkleProof, type(uint256).max, digest, signature);
            return;
        }
        _claimAirdrop(_merkleProof, digest, signature);
    }

    /// @notice Claims airdrop for users who must own an NFT
    /// @param _merkleProof Merkle proof for eligibility verification
    /// @param _tokenId Token ID of the required NFT
    /// @param digest Message digest for signature verification
    /// @param signature User's signature
    function claimAirdrop(bytes32[] calldata _merkleProof, uint256 _tokenId, bytes32 digest, bytes memory signature)
        public
    {
        require(_tokenId == type(uint256).max, Errors.InvalidTokenId());

        require(IERC721(nftAddress).balanceOf(msg.sender) > 0, Errors.NFTNotFound());

        _claimAirdrop(_merkleProof, digest, signature);
    }

    /// @notice Internal function to process airdrop claims
    /// @param _merkleProof Merkle proof for eligibility verification
    /// @param digest Message digest for signature verification
    /// @param signature User's signature
    function _claimAirdrop(bytes32[] calldata _merkleProof, bytes32 digest, bytes memory signature) internal {
        require(_verifySignature(digest, signature), Errors.InvalidSignature());

        require(checkEligibility(_merkleProof), Errors.InvalidClaim());

        require(!isTimeLocked || !hasAirdropTimeEnded(), Errors.AirdropClaimEnded());

        uint256 _currentNoOfClaims = totalNoOfClaimed;

        require(_currentNoOfClaims + 1 <= totalNoOfClaimers, Errors.TotalClaimersExceeded());
        uint256 tokenId = index;

        unchecked {
            ++totalNoOfClaimed;
            ++index;
        }
        hasUserClaimedAirdrop[msg.sender] = true;

        _safeMint(msg.sender, tokenId);
        emit Events.AirdropClaimed(msg.sender, tokenId);
    }

    /// @notice Updates the NFT requirement for claiming
    /// @param _newNft Address of the new required NFT
    function updateNftRequirement(address _newNft) external {
        sanityCheck(_newNft);
        onlyOwner();

        if (nftAddress == address(0)) {
            nftAddress = _newNft;
            isNftRequired = true;
        } else {
            revert Errors.CannotSetAddressTwice();
        }

        emit Events.NftRequirementUpdated(msg.sender, block.timestamp, _newNft);
    }

    /// @notice Toggles the NFT requirement for claiming
    function toggleNftRequirement() external {
        onlyOwner();

        isNftRequired = !isNftRequired;

        emit Events.NftRequirementToggled(msg.sender, block.timestamp);
    }

    /// @notice Updates the claim time period
    /// @param _claimTime New duration for claiming period
    function updateClaimTime(uint256 _claimTime) external {
        onlyOwner();

        isTimeLocked = _claimTime != 0;
         if (_claimTime == 0) {
            airdropEndTime = 0;
        }
        airdropEndTime = block.timestamp + _claimTime;

        emit Events.ClaimTimeUpdated(msg.sender, _claimTime, airdropEndTime);
    }

    /// @notice Verifies if a signature is valid
    /// @param digest Message digest to verify
    /// @param signature Signature to verify
    /// @return bool True if signature is valid, false otherwise
    function _verifySignature(bytes32 digest, bytes memory signature) private view returns (bool) {
        return ECDSA.recover(digest, signature) == msg.sender;
    }

    /// @notice Returns the token URI for a given token ID
    /// @param tokenId ID of the token
    /// @return string URI of the token metadata
    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage) returns (string memory) {
        _requireOwned(tokenId);
        return string(string.concat(baseURI, "/", tokenId.toString()));
    }

    /// @notice Checks if contract supports an interface
    /// @param interfaceId Interface identifier to check
    /// @return bool True if interface is supported, false otherwise
    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
