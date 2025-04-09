// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {SonikDropNative} from "./SonikDropNative.sol";
import {Errors, Events} from "../../libraries/Utils.sol";

/// @title Airdrop Factory Facet
/// @notice Factory contract for creating and managing SonikDropNative instances
/// @dev Handles creation and tracking of SonikDropNative clones with various configurations
contract FactoryFacetNative {
    /// @dev Counter for total number of clones created

    uint256 cloneCount;
    /// @dev Mapping of owner addresses to their SonikDropNative clone contracts
    mapping(address => address[]) ownerToSonikDropNativeCloneContracts;
    /// @dev Array containing addresses of all SonikDropNative clones
    address[] allSonikDropNativeClones;

    /// @notice Creates a new SonikDropNative instance with specified parameters
    /// @dev Internal function to handle the creation logic
    /// @param _merkleRoot Merkle root for validating claims
    /// @param _name Name of the airdrop
    /// @param _nftAddress Address of NFT contract for NFT-gated claims (optional)
    /// @param _claimTime Timestamp for when claims can begin
    /// @param _noOfClaimers Maximum number of allowed claimers
    /// @param _totalOutputTokens Total amount of tokens to be distributed
    /// @return Address of the newly created SonikDropNative contract
    function _createSonikDropNative(
        bytes32 _merkleRoot,
        string memory _name,
        address _nftAddress,
        uint256 _claimTime,
        uint256 _noOfClaimers,
        uint256 _totalOutputTokens
    ) private returns (address) {
        if (msg.sender == address(0)) {
            revert Errors.ZeroAddressDetected();
        }
        if (_noOfClaimers <= 0) {
            revert Errors.ZeroValueDetected();
        }

        if (_totalOutputTokens <= 0) {
            revert Errors.ZeroValueDetected();
        }
        if (msg.value < _totalOutputTokens) {
            revert();
        }

        SonikDropNative _newSonik = new SonikDropNative(
            msg.sender, _merkleRoot, _name, _nftAddress, _claimTime, _noOfClaimers, _totalOutputTokens
        );

        (bool success,) = address(_newSonik).call{value: _totalOutputTokens}("");
        require(success, Errors.TransferFailed());
        ownerToSonikDropNativeCloneContracts[msg.sender].push(address(_newSonik));

        allSonikDropNativeClones.push(address(_newSonik));

        unchecked {
            ++cloneCount;
        }
        emit Events.SonikCloneCreated(msg.sender, block.timestamp, address(_newSonik));

        return address(_newSonik);
    }

    /// @notice Creates a new SonikDropNative with NFT gating
    /// @param _merkleRoot Merkle root for validating claims
    /// @param _name Name of the airdrop
    /// @param _nftAddress Address of NFT contract for NFT-gated claims
    /// @param _noOfClaimers Maximum number of allowed claimers
    /// @param _totalOutputTokens Total amount of tokens to be distributed
    /// @return Address of the newly created SonikDropNative contract
    function createSonikDropNative(
        bytes32 _merkleRoot,
        string memory _name,
        address _nftAddress,
        uint256 _noOfClaimers,
        uint256 _totalOutputTokens
    ) external payable returns (address) {
        return _createSonikDropNative(_merkleRoot, _name, _nftAddress, 0, _noOfClaimers, _totalOutputTokens);
    }

    /// @notice Creates a new SonikDropNative without NFT gating

    /// @param _merkleRoot Merkle root for validating claims
    /// @param _name Name of the airdrop
    /// @param _noOfClaimers Maximum number of allowed claimers
    /// @param _totalOutputTokens Total amount of tokens to be distributed
    /// @return Address of the newly created SonikDropNative contract
    function createSonikDropNative(
        bytes32 _merkleRoot,
        string memory _name,
        uint256 _noOfClaimers,
        uint256 _totalOutputTokens
    ) external payable returns (address) {
        return _createSonikDropNative(_merkleRoot, _name, address(0), 0, _noOfClaimers, _totalOutputTokens);
    }

    /// @notice Retrieves all SonikDropNative clones created by a specific owner
    /// @param _owner Address of the owner
    /// @return Array of addresses of SonikDropNative clones owned by the specified address
    function getOwnerSonikDropNativeClones(address _owner) external view returns (address[] memory) {
        return ownerToSonikDropNativeCloneContracts[_owner];
    }

    /// @notice Retrieves all SonikDropNative clones created through this factory
    /// @return Array of addresses of all SonikDropNative clones
    function getAllSonikDropNativeClones() external view returns (address[] memory) {
        return allSonikDropNativeClones;
    }
}
