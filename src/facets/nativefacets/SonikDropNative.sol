// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {MerkleProof} from "../../libraries/MerkleProof.sol";
import {IERC721} from "../../interfaces/IERC721.sol";
import {Errors, Events} from "../../libraries/Utils.sol";
import {ECDSA} from "../../libraries/ECDSA.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title SonikDropNative
/// @notice A contract for managing native coin (ETH for L1 and most L2, avax etc..) airdrops with optional NFT requirements and time locks
/// @dev Implements merkle proof verification and signature validation for claims

contract SonikDropNative is ReentrancyGuard {
    /// @notice The merkle root used for validating claims

    bytes32 public immutable merkleRoot;
    /// @notice Sonik drop creation time
    uint256 public immutable creationTime;
    /// @notice Name of the airdrop
    string public name;
    /// @notice Address of the contract owner
    address public immutable owner;

    /// @notice Address of the required NFT contract (if any)
    address nftAddress;

    /// @notice Whether the airdrop has a time lock
    bool public isTimeLocked;
    /// @notice Whether the owner has withdrawn remainingNativeCoins
    bool public hasOwnerWithdrawn;
    /// @notice Whether NFT ownership is required to claim
    bool isNftRequired;
    /// @notice Timestamp when the airdrop ends
    uint256 public airdropEndTime;

    /// @notice Total number of eligible claimers
    uint256 internal totalNoOfClaimers;
    /// @notice Total number of successful claims
    uint256 internal totalNoOfClaimed;
    /// @notice Total amount of coin allocated for the airdrop
    uint256 public totalOutputNativeCoins;
    /// @notice Total amount of NativeCoins distributed
    uint256 internal totalAmountSpent;

    /// @notice Mapping to track if a user has claimed their airdrop
    mapping(address user => bool claimed) public hasUserClaimedAirdrop;

    /// @notice Constructor to initialize the airdrop contract
    /// @param _owner Address of the contract owner
    /// @param _merkleRoot Merkle root for validating claims
    /// @param _name Name of the airdrop
    /// @param _nftAddress Address of required NFT contract (if any)
    /// @param _claimTime Duration of the claim period
    /// @param _noOfClaimers Maximum number of eligible claimers
    /// @param _totalOutputNativeCoins Total NativeCoins allocated for airdrop
    constructor(
        address _owner,
        bytes32 _merkleRoot,
        string memory _name,
        address _nftAddress,
        uint256 _claimTime,
        uint256 _noOfClaimers,
        uint256 _totalOutputNativeCoins
    ) {
        merkleRoot = _merkleRoot;
        owner = _owner;
        creationTime = block.timestamp;
        name = _name;
        nftAddress = _nftAddress;

        isNftRequired = _nftAddress != address(0);
        totalNoOfClaimers = _noOfClaimers;
        isTimeLocked = _claimTime != 0;
        if (_claimTime == 0) {
            airdropEndTime = 0;
        }
        airdropEndTime = block.timestamp + _claimTime;
        totalOutputNativeCoins = _totalOutputNativeCoins;
    }

    /// @notice Validates that the provided address is not zero
    /// @param _address Address to validate
    function sanityCheck(address _address) private pure {
        if (_address == address(0)) {
            revert Errors.ZeroAddressDetected();
        }
    }

    /// @notice Validates that the provided amount is greater than zero
    /// @param _amount Amount to validate
    function zeroValueCheck(uint256 _amount) private pure {
        if (_amount <= 0) {
            revert Errors.ZeroValueDetected();
        }
    }

    /// @notice Restricts function access to contract owner
    function onlyOwner() private view {
        require(msg.sender == owner, Errors.UnAuthorizedFunctionCall());
    }

    /// @notice Checks if the airdrop claiming period has ended
    /// @return bool True if airdrop period has ended
    function hasAirdropTimeEnded() public view returns (bool) {
        if (!isTimeLocked) {
            return false;
        }
        return block.timestamp > airdropEndTime;
    }

    /// @notice Gets the current NativeCoins balance of the contract
    /// @return uint256 Current contract balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Checks if a user is eligible to claimNativeCoins
    /// @param _amount Amount of NativeCoins to claim
    /// @param _merkleProof Merkle proof for validation
    /// @return bool True if user is eligible
    function checkEligibility(uint256 _amount, bytes32[] calldata _merkleProof) public view returns (bool) {
        if (hasUserClaimedAirdrop[msg.sender]) {
            return false;
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, _amount))));

        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /// @notice Verifies user signature
    /// @param digest Message hash to verify
    /// @param signature Signature to verify
    /// @return bool True if signature is valid
    function _verifySignature(bytes32 digest, bytes memory signature) private view returns (bool) {
        return ECDSA.recover(digest, signature) == msg.sender;
    }

    /// @notice Allows users to claim their airdrop
    /// @param _amount Amount of NativeCoins to claim
    /// @param _merkleProof Proof of eligibility
    /// @param digest Message hash for signature verification
    /// @param signature User's signature
    function claimAirdrop(uint256 _amount, bytes32[] calldata _merkleProof, bytes32 digest, bytes memory signature)
        external
        nonReentrant
    {
        if (isNftRequired) {
            claimAirdrop(_amount, _merkleProof, type(uint256).max, digest, signature);
            return;
        }
        _claimAirdrop(_amount, _merkleProof, digest, signature);
    }
    /// @notice Allows users to claim airdrop with NFT requirement
    /// @param _amount Amount of NativeCoins to claim
    /// @param _merkleProof Proof of eligibility
    /// @param _tokenId NFT NativeCoins ID (unused)
    /// @param digest Message hash for signature verification
    /// @param signature User's signature

    function claimAirdrop(
        uint256 _amount,
        bytes32[] calldata _merkleProof,
        uint256 _tokenId,
        bytes32 digest,
        bytes memory signature
    ) public nonReentrant {
        require(_tokenId == type(uint256).max, Errors.InvalidTokenId());

        require(IERC721(nftAddress).balanceOf(msg.sender) > 0, Errors.NFTNotFound());
        _claimAirdrop(_amount, _merkleProof, digest, signature);
    }

    /// @notice Internal function to process airdrop claims
    /// @param _amount Amount of NativeCoins to claim
    /// @param _merkleProof Proof of eligibility
    /// @param digest Message hash for signature verification
    /// @param signature User's signature
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

        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, Errors.TransferFailed());
        emit Events.AirdropClaimed(msg.sender, _amount);
    }

    /// @notice Allows owner to withdraw remainingNativeCoins
    ///@dev the withdrawal is only possible if the amount of NativeCoins left in the contract is less than the total amount of NativeCoins claimed by the users
    function withdrawLeftOverNativeCoins() external {
        onlyOwner();
        uint256 contractBalance = getContractBalance();
        zeroValueCheck(contractBalance);

        if (isTimeLocked) {
            if (!hasAirdropTimeEnded()) {
                revert Errors.AirdropClaimTimeNotEnded();
            }
        }
        hasOwnerWithdrawn = true;

        (bool success,) = owner.call{value: contractBalance}("");
        require(success, Errors.TransferFailed());

        emit Events.WithdrawalSuccessful(msg.sender, contractBalance);
    }

    /// @notice Allows owner to fund the airdrop
    function fundAirdrop() external payable {
        onlyOwner();
        zeroValueCheck(msg.value);
        uint256 _amount = msg.value;

        totalOutputNativeCoins = totalOutputNativeCoins + _amount;
        emit Events.AirdropNativeCoinDeposited(msg.sender, _amount);
    }

    /// @notice Updates NFT requirement address
    /// @param _newNft Address of new NFT contract
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

    /// @notice Toggles NFT requirement on/off
    function turnOffNftRequirement() external {
        onlyOwner();
        isNftRequired = !isNftRequired;
        emit Events.NftRequirementToggled(msg.sender, block.timestamp);
    }

    /// @notice Updates the claim period duration
    /// @param _claimTime New duration for claim period
    function updateClaimTime(uint256 _claimTime) external {
        onlyOwner();
        isTimeLocked = _claimTime != 0;
        if (_claimTime == 0) {
            airdropEndTime = 0;
        }
        airdropEndTime = block.timestamp + _claimTime;
        emit Events.ClaimTimeUpdated(msg.sender, _claimTime, airdropEndTime);
    }
}
