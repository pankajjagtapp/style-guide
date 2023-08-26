const fs = require("fs");
const parser = require("@solidity-parser/parser");

const inputFile = "NFT.sol";
const outputFile = "output.sol";
// const astOutput = "ast.sol";

const solidityCode = fs.readFileSync(inputFile, "utf8");
const ast = parser.parse(solidityCode);
// const functions = parser.prettyPrint;

const sortedFunctions = {
  constructor: [],
  receive: [],
  fallback: [],
  external: [],
  externalView: [],
  externalPure: [],
  public: [],
  publicView: [],
  publicPure: [],
  internal: [],
  internalView: [],
  internalPure: [],
  private: [],
  privateView: [],
  privatePure: [],
};

// fs.writeFileSync(astOutput, JSON.stringify(ast.children[4]));
// console.log("==========================ast.children[4].subNodes", ast.children[4].subNodes);

// Categorize functions based on their visibility and type
ast.children[4].subNodes.forEach((node) => {
  // console.log("++++++node====", node);

  if (node.type === "FunctionDefinition") {
    // console.log("IN FUNCTIONS GUYS!!!!!");
    let category = node.visibility;
    // console.log("category: ", category);

    if (node.visibility === "external") {
      if (node.stateMutability === "view") {
        category = "externalView";
      } else if (node.stateMutability === "pure") {
        category = "externalPure";
      } else {
        category = "external";
      }
    }

    if (node.visibility === "public") {
      if (node.stateMutability === "view") {
        category = "publicView";
      } else if (node.stateMutability === "pure") {
        category = "publicPure";
      } else {
        // category = "external";
        category = "public";
      }
    }

    if (node.visibility === "internal") {
      if (node.stateMutability === "view") {
        category = "internalView";
      } else if (node.stateMutability === "pure") {
        category = "internalPure";
      } else {
        // category = "external";
        category = "internal";
      }
    }

    if (node.visibility === "private") {
      if (node.stateMutability === "view") {
        category = "privateView";
      } else if (node.stateMutability === "pure") {
        category = "privatePure";
      } else {
        // category = "external";
        category = "private";
      }
    }

    // if (node.visibility === "public" && node.stateMutability === "view") {
    //   category = "publicView";
    // } else if (
    //   node.visibility === "public" &&
    //   node.stateMutability === "pure"
    // ) {
    //   category = "publicPure";
    // }

    // if (node.visibility === "internal" && node.stateMutability === "view") {
    //   category = "internalView";
    // } else if (
    //   node.visibility === "internal" &&
    //   node.stateMutability === "pure"
    // ) {
    //   category = "internalPure";
    // }

    // if (node.visibility === "private" && node.stateMutability === "view") {
    //   category = "privateView";
    // } else if (
    //   node.visibility === "private" &&
    //   node.stateMutability === "pure"
    // ) {
    //   category = "privatePure";
    // }

    if (node.isConstructor == true) {
      //   console.log("Hey its constructor");
      category = "constructor";
      //   console.log("category changed to constructor", category);
    } else if (node.isReceiveEther == true) {
      category = "receive";
      //   console.log("Hey its receive function", category);
    } else if (node.isFallback == true) {
      category = "fallback";
      //   console.log("Hey its isFallback function", category);
    }

    // console.log("-----------------------------------node", node);
    // console.log("category: ",category);

    sortedFunctions[category].push(node);
  }
});

// Flatten the sorted functions
const sortedFunctionNodes = [
  ...sortedFunctions.constructor,
  ...sortedFunctions.receive,
  ...sortedFunctions.fallback,
  ...sortedFunctions.external,
  ...sortedFunctions.externalView,
  ...sortedFunctions.externalPure,
  ...sortedFunctions.public,
  ...sortedFunctions.publicView,
  ...sortedFunctions.publicPure,
  ...sortedFunctions.internal,
  ...sortedFunctions.internalView,
  ...sortedFunctions.internalPure,
  ...sortedFunctions.private,
  ...sortedFunctions.privateView,
  ...sortedFunctions.privatePure,
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
