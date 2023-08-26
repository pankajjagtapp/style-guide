const fs = require("fs");
const parser = require("solidity-parser-antlr"); 

async function main() {

  const inputFile = "input.sol";
  const outputFile = "output.sol";

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

  // Categorize functions based on their visibility and type
  ast.children.forEach((node) => {
    if (node.type === "FunctionDefinition") {
      let category = node.visibility;

      if (node.kind === "constructor") {
        category = "constructor";
      } else if (node.kind === "receive") {
        category = "receive";
      } else if (node.kind === "fallback") {
        category = "fallback";
      }

      sortedFunctions[category].push(node);
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

  // Create the new contract file with sorted functions
  const sortedContractCode = sortedFunctionNodes
    .map((node) => parser.prettyPrint(node))
    .join("\n\n");
  fs.writeFileSync(outputFile, sortedContractCode);

  console.log(`Sorted functions have been written to ${outputFile}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
