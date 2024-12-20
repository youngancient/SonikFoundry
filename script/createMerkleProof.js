const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");

function generateProof(address, num) {
  let tree;
  // Load the Merkle tree from a JSON file
  if (num == "1") {
    tree = StandardMerkleTree.load(
      JSON.parse(fs.readFileSync("treenft.json", "utf8"))
    );
  } else {
   tree = StandardMerkleTree.load(
    JSON.parse(fs.readFileSync("tree.json", "utf8"))
  );
}

  for (const [i, v] of tree.entries()) {
    if (v[0].toLowerCase() === address.toLowerCase()) {
      // Generate the proof for the given index
      const proof = tree.getProof(i);
      return {
         proof,
      };
    }
  }

  // If the address is not found, return emepty object
  return {
        // value: '',
        proof: "",
      };
}


module.exports = { generateProof };
