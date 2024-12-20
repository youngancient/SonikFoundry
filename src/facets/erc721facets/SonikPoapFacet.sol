// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC721} from "../../interfaces/IERC721.sol";
import {MerkleProof} from "../../libraries/MerkleProof.sol";
import {Errors, Events, IERC721Errors, ERC721Utils} from "../../libraries/Utils.sol";
import {ECDSA} from "../../libraries/ECDSA.sol";
import {Strings} from "../../libraries/utils/Strings.sol";

import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SonikPoapFacet is ERC721URIStorage {
    using Strings for uint256;
    /*====================    Variable  ====================*/

    bytes32 public immutable merkleRoot;
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

        nftAddress = _nftAddress;
        isNftRequired = _nftAddress != address(0);

        totalNoOfClaimers = _noOfClaimers;

        isTimeLocked = _claimTime != 0;
        airdropEndTime = block.timestamp + _claimTime;
    }

    function sanityCheck(address _user) internal pure {
        if (_user == address(0)) {
            revert Errors.ZeroAddressDetected();
        }
    }

    // @dev prevents users from accessing onlyOwner priv ileges
    function onlyOwner() internal view {
        if (msg.sender != owner) {
            revert Errors.UnAuthorizedFunctionCall();
        }
    }
    /*====================  VIew FUnctions ====================*/

    // @dev returns if airdropTime has ended or not
    function hasAirdropTimeEnded() public view returns (bool) {
        return block.timestamp > airdropEndTime;
    }

    function checkEligibility(bytes32[] calldata _merkleProof) public view returns (bool) {
        if (hasUserClaimedAirdrop[msg.sender]) {
            return false;
        }
        // @dev we hash the encoded byte form of the user address and amount to create a leaf
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));

        // @dev check if the merkleProof provided is valid or belongs to the merkleRoot
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }
    // require msg.sender to sign a message before claiming
    // @user for claiming airdrop

    function claimAirdrop(bytes32[] calldata _merkleProof, bytes32 digest, bytes memory signature) external {
        // check if NFT is requiredss
        if (isNftRequired) {
            claimAirdrop(_merkleProof, type(uint256).max, digest, signature);
            return;
        }
        _claimAirdrop(_merkleProof, digest, signature);
    }

    // @user for claiming airdrop with compulsory NFT ownership
    function claimAirdrop(bytes32[] calldata _merkleProof, uint256 _tokenId, bytes32 digest, bytes memory signature)
        public
    {
        require(_tokenId == type(uint256).max, Errors.InvalidTokenId());

        // @dev checks if user has the required NFT
        require(IERC721(nftAddress).balanceOf(msg.sender) > 0, Errors.NFTNotFound());

        _claimAirdrop(_merkleProof, digest, signature);
    }

    function _claimAirdrop(bytes32[] calldata _merkleProof, bytes32 digest, bytes memory signature) internal {
        // verify user signature
        require(_verifySignature(digest, signature), Errors.InvalidSignature());

        //    checks if User is eligible
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

    /*====================  OWNER FUnctions ====================*/

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

    function toggleNftRequirement() external {
        onlyOwner();

        isNftRequired = !isNftRequired;

        emit Events.NftRequirementToggled(msg.sender, block.timestamp);
    }

    function updateClaimTime(uint256 _claimTime) external {
        onlyOwner();

        isTimeLocked = _claimTime != 0;
        airdropEndTime = block.timestamp + _claimTime;

        emit Events.ClaimTimeUpdated(msg.sender, _claimTime, airdropEndTime);
    }

    /*====================  private functions ====================*/
    function zeroValueCheck(uint256 _amount) private pure {
        if (_amount <= 0) {
            revert Errors.ZeroValueDetected();
        }
    }

    // verify user signature
    function _verifySignature(bytes32 digest, bytes memory signature) private view returns (bool) {
        return ECDSA.recover(digest, signature) == msg.sender;
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage) returns (string memory) {
        _requireOwned(tokenId);
        return string(string.concat(baseURI, "/", tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
