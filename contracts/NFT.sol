//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
// import "hardhat/console.sol";

contract SpectralStadiumsNFT is ERC721A, Ownable {
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

    // event NFTsRevealed(uint256[] tokenIds);

    constructor(
        bytes32 presaleMerkleRoot,
        bytes32 privateSaleMerkleRoot
    ) ERC721A("Spectral Stadiums", "SPECTRAL_STADIUMS") {
        _presaleMerkleRoot = presaleMerkleRoot;
        _privateSaleMerkleRoot = privateSaleMerkleRoot;
        _setDefaultRoyalty(owner(), 500);
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

    function setPresaleMerkleRoot(bytes32 root) external onlyOwner {
        _presaleMerkleRoot = root;
    }

    function setPrivateSaleMerkleRoot(bytes32 root) external onlyOwner {
        _privateSaleMerkleRoot = root;
    }

    function startPresale() external onlyOwner {
        if (presaleActive) revert SaleActive();
        presaleActive = true;
    }

    function startPrivateSale() external onlyOwner {
        if (privateSaleActive) revert SaleActive();
        privateSaleActive = true;
    }

    function startPublicSale() external onlyOwner {
        if (publicSaleActive) revert SaleActive();
        publicSaleActive = true;
    }

    function pausePresale() external onlyOwner {
        if (!presaleActive) revert SaleNotActive();
        presaleActive = false;
    }

    function pausePrivateSale() external onlyOwner {
        if (!privateSaleActive) revert SaleNotActive();
        privateSaleActive = false;
    }

    function pausePublicSale() external onlyOwner {
        if (!publicSaleActive) revert SaleNotActive();
        publicSaleActive = false;
    }

    function reveal() external onlyOwner {
        if (!publicSaleActive) revert SaleNotActive();
        require(!NFTsRevealed, "Reveal has already started.");
        NFTsRevealed = true;
    }

    function mintPresale(
        uint256 quantity,
        bytes32[] memory proof
    ) external payable onlyPresale(proof) {
        _basicChecks(quantity);
        if (preSaleNFTs[msg.sender] + quantity > PRESALE_MAX_MINT)
            revert WalletLimitExceeded();

        preSaleNFTs[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mintPrivateSale(
        uint256 quantity,
        bytes32[] memory proof
    ) external payable onlyPrivateSale(proof) {
        _basicChecks(quantity);
        if (privateSaleNFTs[msg.sender] + quantity > PRIVATE_SALE_MAX_MINT)
            revert WalletLimitExceeded();

        privateSaleNFTs[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mintPublicSale(uint256 quantity) external payable {
        if (!publicSaleActive) revert SaleNotActive();
        _basicChecks(quantity);
        if (publicSaleNFTs[msg.sender] + quantity > PUBLIC_SALE_MAX_MINT)
            revert WalletLimitExceeded();

        publicSaleNFTs[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
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

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) private {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() private {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function changeRevealed(bool _revealed) external onlyOwner {
        NFTsRevealed = _revealed;
    }

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
}

/**
 * custom ERC721A smart contract for an NFT collection called Spectral Stadiums
 * 
The Collection is of 5575 NFTs => Done

Include these features:

Whitelisting addresses for presale => Done
Whitelisting addresses for Private sale => Done

Presale for whitelisted address => Done
Private sale for whitelisted addresses => Done

Public sale for everyone => Done

In Pre sale each wallet can mint 3 NFTs => Done
In Public sale each wallet can mint 5 NFTs => Done

PreSale = 20 NFTS     -------------------------------------------------------------------

Royalty on secondary sale is 5% => Done

delayed Reveal of NFTs after public sale that can be done manually => Done

Price of NFT is 0.035 ETH => Done

 */
