const fs = require("fs");
const parser = require("@solidity-parser/parser");

const inputFile = "NFT.sol";
const outputFile = "output.sol";
// const astOutput = "ast.sol";

const solidityCode = fs.readFileSync(inputFile, "utf8");
const ast = parser.parse(solidityCode);

const sortedFunctions = {
  constructor: [],
  receive: [],
  fallback: [],
  external: [],
  public: [],
  internal: [],
  private: [],
};

// fs.writeFileSync(astOutput, JSON.stringify(ast.children[4]));
// console.log("==========================ast.children[4].subNodes", ast.children[4].subNodes);

// Categorize functions based on their visibility and type
ast.children[4].subNodes.forEach((node) => {
  // console.log("++++++node====", node);

  if (node.type === "FunctionDefinition") {
    console.log("IN FUNCTIONS GUYS!!!!!");
    let category = node.visibility;
    console.log("category: ", category);

    if (node.isConstructor == true) {
      console.log("Hey its constructor");
      node.visibility = "constructor";
      console.log("category changed to constructor", node.visibility);
    } else if (node.isReceiveEther == true) {
      node.visibility = "receive";
      console.log("Hey its receive function", node.visibility);
    } else if (node.isFallback == true) {
      node.visibility = "fallback";
      console.log("Hey its isFallback function", node.visibility);
    }

    // console.log("-----------------------------------node", node);
    // console.log("category: ",category);

    sortedFunctions[node.visibility].push(node);
  }
});

// Flatten the sorted functions
const sortedFunctionNodes = [
  ...sortedFunctions.constructor,
  ...sortedFunctions.receive,
  ...sortedFunctions.fallback,
  ...sortedFunctions.external,
  ...sortedFunctions.public,
  ...sortedFunctions.internal,
  ...sortedFunctions.private,
];

console.log(
  "++++++++++++++++++++++++++++++++++++++++++++++++sortedFunctionNodes:",
  sortedFunctionNodes
);

// // Create the new contract file with sorted functions
// const sortedContractCode = sortedFunctionNodes
//   .map((node) => parser.prettyPrint(node))
//   .join("\n\n");
// fs.writeFileSync(outputFile, sortedContractCode);

console.log(`Sorted functions have been written to ${outputFile}`);
