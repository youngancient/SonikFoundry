const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");
const { values, valuesnft } = require("./airdrop_list");


const tree = StandardMerkleTree.of(values, ["address" ,"uint256"]);
const treenft = StandardMerkleTree.of(valuesnft, ["address" ]);

// (3) Output the Merkle root
console.log("Merkle Root:", tree.root);
console.log("Merkle RootNft:", treenft.root);

// (4) Write the Merkle tree data to a JSON file
fs.writeFileSync("tree.json", JSON.stringify(tree.dump(), null, 1), "utf8");
fs.writeFileSync("treenft.json", JSON.stringify(treenft.dump(), null, 1), "utf8");

console.log("JSON file created: tree.json");
console.log("JSON file created: treenft.json");
