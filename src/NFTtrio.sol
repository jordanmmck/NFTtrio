// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTtrio is ERC721, ERC2981, Ownable2Step {
    uint256 public constant MAX_SUPPLY = 20;
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant DISCOUNT_FACTOR = 2;
    uint96 public constant ROYALTY = 250; // basis points
    bytes32 public immutable merkleRoot;
    uint256 public currentSupply;

    address private immutable _royaltyReceiver;
    uint256 private _royalties;
    BitMaps.BitMap private _discountList;

    constructor(bytes32 _merkleRoot, address royaltyReceiver) ERC721("NFTtrio", "NFT3") {
        require(royaltyReceiver != address(0), "Invalid royalty receiver");
        _royaltyReceiver = royaltyReceiver;
        _setDefaultRoyalty(royaltyReceiver, ROYALTY);
        merkleRoot = _merkleRoot;
    }

    function mint() public payable {
        require(msg.value == PRICE, "Incorrect price");
        require(currentSupply < MAX_SUPPLY, "All tokens minted");
        require(balanceOf(msg.sender) < 2, "Only two NFTs per address");

        _safeMint(msg.sender, currentSupply);

        (, uint256 royaltyAmount) = royaltyInfo(currentSupply, PRICE);
        _royalties += royaltyAmount;

        currentSupply++;
    }

    function mintWithDiscount(bytes32[] calldata proof, uint256 index) external payable {
        require(msg.value == PRICE / 2, "Incorrect price");
        require(currentSupply < MAX_SUPPLY, "All tokens minted");
        require(balanceOf(msg.sender) < 2, "Only two NFTs per address");
        require(!BitMaps.get(_discountList, index), "Discount already used");

        _verifyProof(proof, index);

        // set discount as used
        BitMaps.setTo(_discountList, index, true);

        _safeMint(msg.sender, currentSupply);

        (, uint256 royaltyAmount) = royaltyInfo(currentSupply, PRICE / DISCOUNT_FACTOR);
        _royalties += royaltyAmount;

        currentSupply++;
    }

    function withdrawRoyalties() external {
        require(msg.sender == _royaltyReceiver, "Only royalty receiever can withdraw");
        require(_royalties > 0, "No royalties to withdraw");

        uint256 amount = _royalties;
        _royalties = 0;
        payable(msg.sender).transfer(amount);
    }

    function withdrawReserves() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance - _royalties);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return interfaceId == type(ERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function _verifyProof(bytes32[] memory proof, uint256 index) private view {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, index))));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
    }
}
