import "forge-std/Test.sol";
import "solidity-stringutils/strings.sol";
import {stdJson} from "forge-std/StdJson.sol";

abstract contract GetProof is Test {
    using strings for *;

    struct Proof {
        bytes32[] proof;
    }

    function toString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(uint256 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes32 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function getProof(address _userAddress) internal returns (bytes32[] memory) {
        // Command to call the Node.js script with the user address as argument
        string[] memory cmd = new string[](4);
        cmd[0] = "node";
        cmd[1] = "script/checkProofForAddressCli.js";
        cmd[2] = toString(_userAddress);
        cmd[3] = "0";

        // Call the script and get the response
        bytes memory res = vm.ffi(cmd);
        string memory st = string(res);

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/proof.json");
        // string memory path = ;
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);

        Proof memory proofs = abi.decode(data, (Proof));

        for (uint256 i = 0; i < proofs.proof.length; i++) {
            bytes32 mproof = proofs.proof[i];

            console2.logBytes32(mproof);
        }
        return proofs.proof;
    }

    function getProofPoap(address _userAddress) internal returns (bytes32[] memory) {
        // Command to call the Node.js script with the user address as argument
        string[] memory cmd = new string[](4);
        cmd[0] = "node";
        cmd[1] = "script/checkProofForAddressCli.js";
        cmd[2] = toString(_userAddress);
        cmd[3] = "1";

        // Call the script and get the response
        bytes memory res = vm.ffi(cmd);
        string memory st = string(res);

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/proofNFT.json");
        // string memory path = ;
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);

        Proof memory proofs = abi.decode(data, (Proof));

        for (uint256 i = 0; i < proofs.proof.length; i++) {
            bytes32 mproof = proofs.proof[i];

            console2.logBytes32(mproof);
        }
        return proofs.proof;
    }
}
