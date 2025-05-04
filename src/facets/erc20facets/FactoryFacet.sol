// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SonikDrop} from "./SonikDrop.sol";
import {Errors, Events} from "../../libraries/Utils.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Airdrop Factory Facet
/// @notice Factory contract for creating and managing SonikDrop instances
/// @dev Handles creation and tracking of SonikDrop clones with various configurations
contract AirdropFactoryFacet {
    using SafeERC20 for IERC20;
    /// @dev Counter for total number of clones created

    uint256 public cloneCount;
    /// @dev Mapping of owner addresses to their SonikDrop clone contracts
    mapping(address => address[]) public ownerToSonikDropCloneContracts;
    /// @dev Array containing addresses of all SonikDrop clones
    address[] public allSonikDropClones;

    /// @notice Creates a new SonikDrop instance with specified parameters
    /// @dev Internal function to handle the creation logic
    /// @param _tokenAddress Address of the ERC20 token to be distributed
    /// @param _merkleRoot Merkle root for validating claims
    /// @param _name Name of the airdrop
    /// @param _nftAddress Address of NFT contract for NFT-gated claims (optional)
    /// @param _claimTime Timestamp for when claims can begin
    /// @param _noOfClaimers Maximum number of allowed claimers
    /// @param _totalOutputTokens Total amount of tokens to be distributed
    /// @return Address of the newly created SonikDrop contract
    function _createSonikDrop(
        address _tokenAddress,
        bytes32 _merkleRoot,
        string memory _name,
        address _nftAddress,
        uint256 _claimTime,
        uint256 _noOfClaimers,
        uint256 _totalOutputTokens
    ) private returns (address) {
        if (_noOfClaimers <= 0) {
            revert Errors.ZeroValueDetected();
        }

        if (_totalOutputTokens <= 0) {
            revert Errors.ZeroValueDetected();
        }

        SonikDrop _newSonik = new SonikDrop(
            msg.sender, _tokenAddress, _merkleRoot, _name, _nftAddress, _claimTime, _noOfClaimers, _totalOutputTokens
        );

        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(_newSonik), _totalOutputTokens);

        ownerToSonikDropCloneContracts[msg.sender].push(address(_newSonik));

        allSonikDropClones.push(address(_newSonik));

        unchecked {
            ++cloneCount;
        }
        emit Events.SonikCloneCreated(msg.sender, block.timestamp, address(_newSonik));

        return address(_newSonik);
    }

    /// @notice Creates a new SonikDrop with NFT gating
    /// @param _tokenAddress Address of the ERC20 token to be distributed
    /// @param _merkleRoot Merkle root for validating claims
    /// @param _name Name of the airdrop
    /// @param _nftAddress Address of NFT contract for NFT-gated claims
    /// @param _noOfClaimers Maximum number of allowed claimers
    /// @param _totalOutputTokens Total amount of tokens to be distributed
    /// @return Address of the newly created SonikDrop contract
    function createSonikDrop(
        address _tokenAddress,
        bytes32 _merkleRoot,
        string memory _name,
        address _nftAddress,
        uint256 _noOfClaimers,
        uint256 _totalOutputTokens
    ) external returns (address) {
        return _createSonikDrop(_tokenAddress, _merkleRoot, _name, _nftAddress, 0, _noOfClaimers, _totalOutputTokens);
    }

    /// @notice Creates a new SonikDrop without NFT gating
    /// @param _tokenAddress Address of the ERC20 token to be distributed
    /// @param _merkleRoot Merkle root for validating claims
    /// @param _name Name of the airdrop
    /// @param _noOfClaimers Maximum number of allowed claimers
    /// @param _totalOutputTokens Total amount of tokens to be distributed
    /// @return Address of the newly created SonikDrop contract
    function createSonikDrop(
        address _tokenAddress,
        bytes32 _merkleRoot,
        string memory _name,
        uint256 _noOfClaimers,
        uint256 _totalOutputTokens
    ) external returns (address) {
        return _createSonikDrop(_tokenAddress, _merkleRoot, _name, address(0), 0, _noOfClaimers, _totalOutputTokens);
    }

    /// @notice Retrieves all SonikDrop clones created by a specific owner
    /// @param _owner Address of the owner
    /// @return Array of addresses of SonikDrop clones owned by the specified address
    function getOwnerSonikDropClones(address _owner) external view returns (address[] memory) {
        return ownerToSonikDropCloneContracts[_owner];
    }

    /// @notice Retrieves all SonikDrop clones created through this factory
    /// @return Array of addresses of all SonikDrop clones
    function getAllSonikDropClones() external view returns (address[] memory) {
        return allSonikDropClones;
    }
}
