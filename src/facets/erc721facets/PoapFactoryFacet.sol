// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {SonikPoapFacet} from "./SonikPoapFacet.sol";
import {Errors, Events} from "../../libraries/Utils.sol";

/// @title POAP Factory Facet
/// @notice Manages the creation and tracking of Sonik POAP contracts
/// @dev Implements factory pattern for deploying new POAP contracts with various configurations
contract PoapFactoryFacet {
    uint256 clonePoapCount;
    mapping(address => address[]) ownerToSonikPoapCloneContracts;
    address[] allSonikPoapClones;

    /// @notice Creates a new Sonik POAP contract with specified parameters
    /// @param _name Name of the POAP token
    /// @param _symbol Symbol of the POAP token
    /// @param _baseURI Base URI for token metadata
    /// @param _merkleRoot Merkle root for whitelist verification
    /// @param _nftAddress Address of required NFT for claiming (if any)
    /// @param _claimTime Timestamp when claiming becomes available (0 for immediate)
    /// @param _noOfClaimers Maximum number of allowed claimers
    /// @dev Reverts if sender is zero address or number of claimers is zero
    function _createSonikPoap(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bytes32 _merkleRoot,
        address _nftAddress,
        uint256 _claimTime,
        uint256 _noOfClaimers,
        bool _isCollection
    ) private {
        if (_noOfClaimers <= 0) {
            revert Errors.ZeroValueDetected();
        }

        SonikPoapFacet _newSonikPoap = new SonikPoapFacet(
            _name, _symbol, _baseURI, msg.sender, _merkleRoot, _nftAddress, _claimTime, _noOfClaimers, _isCollection
        );

        ownerToSonikPoapCloneContracts[msg.sender].push(address(_newSonikPoap));
        allSonikPoapClones.push(address(_newSonikPoap));
        ++clonePoapCount;

        emit Events.SonikPoapCloneCreated(msg.sender, block.timestamp, address(_newSonikPoap));
    }

    /// @notice Creates a POAP with NFT requirement and time lock
    /// @param _name Name of the POAP token
    /// @param _symbol Symbol of the POAP token
    /// @param _baseURI Base URI for token metadata
    /// @param _merkleRoot Merkle root for whitelist verification
    /// @param _nftAddress Address of required NFT for claiming
    /// @param _claimTime Timestamp when claiming becomes available
    /// @param _noOfClaimers Maximum number of allowed claimers
    function createSonikPoap(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bytes32 _merkleRoot,
        address _nftAddress,
        uint256 _claimTime,
        uint256 _noOfClaimers
    ) external {
        return _createSonikPoap(_name, _symbol, _baseURI, _merkleRoot, _nftAddress, _claimTime, _noOfClaimers, false);
    }
    /// @notice Creates a POAP with NFT requirement and time lock and Collection (this is configurable)
    /// @param _name Name of the POAP token
    /// @param _symbol Symbol of the POAP token
    /// @param _baseURI Base URI for token metadata
    /// @param _merkleRoot Merkle root for whitelist verification
    /// @param _nftAddress Address of required NFT for claiming
    /// @param _claimTime Timestamp when claiming becomes available
    /// @param _noOfClaimers Maximum number of allowed claimers

    function createSonikPoap(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bytes32 _merkleRoot,
        address _nftAddress,
        uint256 _claimTime,
        uint256 _noOfClaimers,
        bool _isCollection
    ) external {
        return _createSonikPoap(
            _name, _symbol, _baseURI, _merkleRoot, _nftAddress, _claimTime, _noOfClaimers, _isCollection
        );
    }
    /// @notice Creates a POAP with NFT requirement but no time lock
    /// @param _name Name of the POAP token
    /// @param _symbol Symbol of the POAP token
    /// @param _baseURI Base URI for token metadata
    /// @param _merkleRoot Merkle root for whitelist verification
    /// @param _nftAddress Address of required NFT for claiming
    /// @param _noOfClaimers Maximum number of allowed claimers

    function createSonikPoap(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bytes32 _merkleRoot,
        address _nftAddress,
        uint256 _noOfClaimers
    ) external {
        return _createSonikPoap(_name, _symbol, _baseURI, _merkleRoot, _nftAddress, 0, _noOfClaimers, false);
    }

    /// @notice Creates a basic POAP without NFT requirement or time lock
    /// @param _name Name of the POAP token
    /// @param _symbol Symbol of the POAP token
    /// @param _baseURI Base URI for token metadata
    /// @param _merkleRoot Merkle root for whitelist verification
    /// @param _noOfClaimers Maximum number of allowed claimers
    function createSonikPoap(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bytes32 _merkleRoot,
        uint256 _noOfClaimers
    ) external {
        return _createSonikPoap(_name, _symbol, _baseURI, _merkleRoot, address(0), 0, _noOfClaimers, false);
    }
    /// @notice Retrieves all POAPs created by a specific owner
    /// @param _owner Address of the POAP creator
    /// @return Array of addresses of POAP contracts created by the owner

    function getOwnerSonikPoapClones(address _owner) external view returns (address[] memory) {
        return ownerToSonikPoapCloneContracts[_owner];
    }

    /// @notice Retrieves all POAP clone addresses
    /// @return Array of all POAP contract addresses
    function getAllSonikPoapClones() external view returns (address[] memory) {
        return allSonikPoapClones;
    }
}
