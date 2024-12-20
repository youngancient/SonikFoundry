// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {SonikPoapFacet} from "./SonikPoapFacet.sol";
import {Errors, Events} from "../../libraries/Utils.sol";

contract PoapFactoryFacet {
    uint256 clonePoapCount;
    mapping(address => address[]) ownerToSonikPoapCloneContracts;
    address[] allSonikPoapClones;

    function _createSonikPoap(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bytes32 _merkleRoot,
        address _nftAddress,
        uint256 _claimTime,
        uint256 _noOfClaimers
    ) private {
        if (msg.sender == address(0)) {
            revert Errors.ZeroAddressDetected();
        }
        if (_noOfClaimers <= 0) {
            revert Errors.ZeroValueDetected();
        }

        SonikPoapFacet _newSonikPoap = new SonikPoapFacet(
            _name, _symbol, _baseURI, msg.sender, _merkleRoot, _nftAddress, _claimTime, _noOfClaimers
        );

        ownerToSonikPoapCloneContracts[msg.sender].push(address(_newSonikPoap));
        allSonikPoapClones.push(address(_newSonikPoap));
        ++clonePoapCount;

        emit Events.SonikPoapCloneCreated(msg.sender, block.timestamp, address(_newSonikPoap));
    }

    // Create POAP with NFT requirement and time lock
    function createSonikPoap(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bytes32 _merkleRoot,
        address _nftAddress,
        uint256 _claimTime,
        uint256 _noOfClaimers
    ) external {
        return _createSonikPoap(_name, _symbol, _baseURI, _merkleRoot, _nftAddress, _claimTime, _noOfClaimers);
    }

    // Create POAP with NFT requirement but no time lock
    function createSonikPoap(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bytes32 _merkleRoot,
        address _nftAddress,
        uint256 _noOfClaimers
    ) external {
        return _createSonikPoap(_name, _symbol, _baseURI, _merkleRoot, _nftAddress, 0, _noOfClaimers);
    }

    // Create basic POAP without NFT requirement or time lock
    function createSonikPoap(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bytes32 _merkleRoot,
        uint256 _noOfClaimers
    ) external {
        return _createSonikPoap(_name, _symbol, _baseURI, _merkleRoot, address(0), 0, _noOfClaimers);
    }

    // Get all POAPs created by a specific owner
    function getOwnerSonikPoapClones(address _owner) external view returns (address[] memory) {
        return ownerToSonikPoapCloneContracts[_owner];
    }

    // Get all POAP clone addresses
    function getAllSonikPoapClones() external view returns (address[] memory) {
        return allSonikPoapClones;
    }
}
