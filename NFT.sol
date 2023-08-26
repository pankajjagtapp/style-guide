//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// import "hardhat/console.sol";

contract DemoContract is ERC721A, Ownable {
    uint256 public constant PRESALE_MAX_MINT = 3;
    uint256 public constant PRIVATE_SALE_MAX_MINT = 3;
    uint256 public constant PUBLIC_SALE_MAX_MINT = 5;
    uint256 public constant MAX_SUPPLY = 5575;
    uint256 public constant PRICE = 0.035 ether;

    bytes32 private _presaleMerkleRoot;
    bytes32 private _privateSaleMerkleRoot;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    mapping(address => uint256) public preSaleNFTs;
    mapping(address => uint256) public privateSaleNFTs;
    mapping(address => uint256) public publicSaleNFTs;

    string private baseURI = "ipfs://THISISTHECID/";

    bool public presaleActive;
    bool public privateSaleActive;
    bool public publicSaleActive;
    bool public NFTsRevealed;

    error SaleActive();
    error SaleNotActive();
    error ZeroQuantity(); // Instead of => require(quantity > 0, "Quantity should be greater than zero.");
    error MaxSupplyExceeded(); // Instead of => require(_tokenIdCounter.current() + quantity <= MAX_SUPPLY,"Exceeded maximum supply.");
    error InsufficientAmount(); // Instead of => require(msg.value >= PRICE * quantity, "Insufficient ETH amount.");
    error WalletLimitExceeded();
    error AddressNotWhitelisted(); // Instead of => // require(_verifyMerkleProof(proof, _privateSaleMerkleRoot, msg.sender),"Address is not whitelisted for private sale.");

    event PresaleMint(address indexed recipient, uint256[] tokenIds);
    event PrivateSaleMint(address indexed recipient, uint256[] tokenIds);
    event PublicSaleMint(address indexed recipient, uint256[] tokenIds);
    event FundsWIthdrawn(address indexed recipient, uint256 amount);

    function _feeDenominator() private pure returns (uint96) {
        return 10000;
    }

    modifier onlyPresale(bytes32[] memory proof) {
        if (!presaleActive) revert SaleNotActive();
        if (!_verifyMerkleProof(proof, _presaleMerkleRoot, msg.sender))
            revert AddressNotWhitelisted();
        _;
    }

    modifier onlyPrivateSale(bytes32[] memory proof) {
        if (!privateSaleActive) revert SaleNotActive();
        if (!_verifyMerkleProof(proof, _privateSaleMerkleRoot, msg.sender))
            revert AddressNotWhitelisted();
        _;
    }

    function setPresaleMerkleRoot(bytes32 root) public onlyOwner {
        _presaleMerkleRoot = root;
    }

    function _basicChecks(uint256 quantity) internal view {
        if (quantity <= 0) {
            revert ZeroQuantity();
        }
        if (_nextTokenId() + quantity > MAX_SUPPLY) {
            revert MaxSupplyExceeded();
        }
        if (msg.value < PRICE * quantity) {
            revert InsufficientAmount();
        }
    }

    function _verifyMerkleProof(
        bytes32[] memory proof,
        bytes32 root,
        address recipient
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(recipient));
        return MerkleProof.verify(proof, root, leaf);
    }

    function withdrawFunds() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "ZERO_AMOUNT");
        payable(owner()).transfer(amount);
    }

    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) private {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeRevealed(bool _revealed) external onlyOwner payable {
        NFTsRevealed = _revealed;
    }

    fallback() external payable {}

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI_ = _baseURI();

        if (NFTsRevealed) {
            return
                bytes(baseURI_).length != 0
                    ? string(
                        abi.encodePacked(baseURI_, _toString(tokenId), ".json")
                    )
                    : "";
        } else {
            return string(abi.encodePacked(baseURI_, "hidden.json"));
        }
    }

    receive() external payable {}

    constructor(
        bytes32 presaleMerkleRoot,
        bytes32 privateSaleMerkleRoot
    ) ERC721A("Spectral Stadiums", "SPECTRAL_STADIUMS") {
        _presaleMerkleRoot = presaleMerkleRoot;
        _privateSaleMerkleRoot = privateSaleMerkleRoot;
        _setDefaultRoyalty(owner(), 500);
    }
}
