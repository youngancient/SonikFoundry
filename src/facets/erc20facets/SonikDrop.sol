// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {MerkleProof} from "../../libraries/MerkleProof.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {IERC721} from "../../interfaces/IERC721.sol";
import {Errors, Events} from "../../libraries/Utils.sol";
import {LibDiamond} from "../../libraries/LibDiamond.sol";
import {ECDSA} from "../../libraries/ECDSA.sol";

// another possible feature is time-locking the airdrop
// i.e people can only claim within a certain time
// owners cannot withdraw tokens within that time

// TODO add a way to check if the airdrop has ended and owner wthdraw
contract SonikDrop {
    bytes32 public immutable merkleRoot;
    string public name;
    address public immutable owner;
    address public immutable tokenAddress;
    address nftAddress;

    bool public isTimeLocked;
    bool public hasOwnerWithdrawn;
    bool isNftRequired;
    uint256 public airdropEndTime;

    uint256 internal totalNoOfClaimers;
    uint256 internal totalNoOfClaimed;
    uint256 public totalOutputTokens;

    uint256 internal totalAmountSpent; // total for airdrop token spent

    mapping(address user => bool claimed) public hasUserClaimedAirdrop;

    constructor(
        address _owner,
        address _tokenAddress,
        bytes32 _merkleRoot,
        string memory _name,
        address _nftAddress,
        uint256 _claimTime,
        uint256 _noOfClaimers,
        uint256 _totalOutputTokens
    ) {
        merkleRoot = _merkleRoot;

        owner = _owner;

        tokenAddress = _tokenAddress;
        name = _name;

        nftAddress = _nftAddress;

        isNftRequired = _nftAddress != address(0);

        totalNoOfClaimers = _noOfClaimers;

        isTimeLocked = _claimTime != 0;
        airdropEndTime = block.timestamp + _claimTime;
        totalOutputTokens = _totalOutputTokens;
    }
    // @dev prevents zero address from interacting with the contract

    function sanityCheck(address _user) private pure {
        if (_user == address(0)) {
            revert Errors.ZeroAddressDetected();
        }
    }

    function zeroValueCheck(uint256 _amount) private pure {
        if (_amount <= 0) {
            revert Errors.ZeroValueDetected();
        }
    }

    // @dev prevents users from accessing onlyOwner privileges
    function onlyOwner() private view {
        require(msg.sender == owner, Errors.UnAuthorizedFunctionCall());
    }

    // @dev returns if airdropTime has ended or not for time locked airdrop
    function hasAirdropTimeEnded() public view returns (bool) {
        return block.timestamp > airdropEndTime;
    }

    // @dev checks contract token balance
    function getContractBalance() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // @user check for eligibility

    function checkEligibility(uint256 _amount, bytes32[] calldata _merkleProof) public view returns (bool) {
        if (hasUserClaimedAirdrop[msg.sender]) {
            return false;
        }

        // @dev we hash the encoded byte form of the user address and amount to create a leaf
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, _amount))));

        // @dev check if the merkleProof provided is valid or belongs to the merkleRoot
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    // verify user signature

    function _verifySignature(bytes32 digest, bytes memory signature) private view returns (bool) {
        return ECDSA.recover(digest, signature) == msg.sender;
    }

    // require msg.sender to sign a message before claiming
    // @user for claiming airdrop
    function claimAirdrop(uint256 _amount, bytes32[] calldata _merkleProof, bytes32 digest, bytes memory signature)
        external
    {
        // check if NFT is required
        if (isNftRequired) {
            claimAirdrop(_amount, _merkleProof, type(uint256).max, digest, signature);
            return;
        }
        _claimAirdrop(_amount, _merkleProof, digest, signature);
    }

    // @user for claiming airdrop with compulsory NFT ownership
    function claimAirdrop(
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        uint256 _tokenId,
        bytes32 digest,
        bytes memory signature
    ) public {
        require(_tokenId == type(uint256).max, Errors.InvalidTokenId());

        // @dev checks if user has the required NFT
        require(IERC721(nftAddress).balanceOf(msg.sender) > 0, Errors.NFTNotFound());

        _claimAirdrop(_amount, _merkleProof, digest, signature);
    }

    function _claimAirdrop(uint256 _amount, bytes32[] calldata _merkleProof, bytes32 digest, bytes memory signature)
        internal
    {
        // verify user signature
        require(_verifySignature(digest, signature), Errors.InvalidSignature());

        // checks if User is eligible
        require(checkEligibility(_amount, _merkleProof), Errors.InvalidClaim());

        require(!isTimeLocked || !hasAirdropTimeEnded(), Errors.AirdropClaimEnded());

        uint256 _currentNoOfClaims = totalNoOfClaimed;

        require(_currentNoOfClaims + 1 <= totalNoOfClaimers, Errors.TotalClaimersExceeded());
        require(getContractBalance() >= _amount, Errors.InsufficientContractBalance());

        unchecked {
            ++totalNoOfClaimed;
        }

        hasUserClaimedAirdrop[msg.sender] = true;

        totalAmountSpent = totalAmountSpent + _amount;

        require(IERC20(tokenAddress).transfer(msg.sender, _amount), Errors.TransferFailed());

        emit Events.AirdropClaimed(msg.sender, _amount);
    }

    // @user For owner to withdraw left over tokens

    /* @dev the withdrawal is only possible if the amount of tokens left in the contract
        is less than the total amount of tokens claimed by the users
    */
    function withdrawLeftOverToken() external {
        onlyOwner();
        uint256 contractBalance = getContractBalance();
        zeroValueCheck(contractBalance);

        if (isTimeLocked) {
            if (!hasAirdropTimeEnded()) {
                revert Errors.AirdropClaimTimeNotEnded();
            }
        }
        hasOwnerWithdrawn = true;

        if (!IERC20(tokenAddress).transfer(owner, contractBalance)) {
            revert Errors.WithdrawalFailed();
        }

        emit Events.WithdrawalSuccessful(msg.sender, contractBalance);
    }

    // @user for owner to fund the airdrop
    function fundAirdrop(uint256 _amount) external {
        onlyOwner();
        zeroValueCheck(_amount);

        if (!IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount)) {
            revert Errors.TransferFailed();
        }
        totalOutputTokens = totalOutputTokens + _amount;
        emit Events.AirdropTokenDeposited(msg.sender, _amount);
    }

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

    function turnOffNftRequirement() external {
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
}
