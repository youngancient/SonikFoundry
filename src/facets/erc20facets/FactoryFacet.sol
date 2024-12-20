// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC20} from "../../interfaces/IERC20.sol";
import {SonikDrop} from "./SonikDrop.sol";
import {Errors, Events} from "../../libraries/Utils.sol";

contract AirdropFactoryFacet {
    //  when a person interacts with the factory, he would options like
    // 1. Adding an NFT requirement
    // 2. Adding a time lock
    uint256 cloneCount;
    mapping(address => address[]) ownerToSonikDropCloneContracts;
    address[] allSonikDropClones;

    function _createSonikDrop(
        address _tokenAddress,
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

        SonikDrop _newSonik =
            new SonikDrop(msg.sender, _tokenAddress, _merkleRoot, _name, _nftAddress, _claimTime, _noOfClaimers);

        bool success = IERC20(_tokenAddress).transferFrom(msg.sender, address(_newSonik), _totalOutputTokens);
        require(success, Errors.TransferFailed());

        ownerToSonikDropCloneContracts[msg.sender].push(address(_newSonik));

        allSonikDropClones.push(address(_newSonik));

        unchecked {
            ++cloneCount;
        }
        emit Events.SonikCloneCreated(msg.sender, block.timestamp, address(_newSonik));

        return address(_newSonik);
    }

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

    function createSonikDrop(
        address _tokenAddress,
        bytes32 _merkleRoot,
        string memory _name,
        uint256 _noOfClaimers,
        uint256 _totalOutputTokens
    ) external returns (address) {
        return _createSonikDrop(_tokenAddress, _merkleRoot, _name, address(0), 0, _noOfClaimers, _totalOutputTokens);
    }

    function getOwnerSonikDropClones(address _owner) external view returns (address[] memory) {
        return ownerToSonikDropCloneContracts[_owner];
    }

    function getAllSonikDropClones() external view returns (address[] memory) {
        return allSonikDropClones;
    }
}
