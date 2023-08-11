// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RewardToken} from "./RewardToken.sol";

contract Staking is IERC721Receiver {
    struct Deposit {
        address depositer;
        uint256 block;
    }

    // blocks per day
    uint256 public constant REWARD_DELAY = 17280;
    mapping(uint256 => Deposit) private _deposits;
    address public immutable nftAddress;
    address public immutable tokenAddress;
    uint256 public immutable tokenDecimals;

    constructor(address _nftAddress, address _tokenAddress) {
        require(_nftAddress != address(0), "Zero address");
        require(_tokenAddress != address(0), "Zero address");
        nftAddress = _nftAddress;
        tokenAddress = _tokenAddress;
        // is this bad practice to call an external contract in the constructor?
        tokenDecimals = ERC20(_tokenAddress).decimals();
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external returns (bytes4) {
        _deposits[tokenId] = Deposit(from, block.number);
        return IERC721Receiver.onERC721Received.selector;
    }

    function collectTokens(uint256 tokenID) external {
        Deposit memory deposit = _deposits[tokenID];

        require(deposit.depositer == msg.sender, "Must be owner of NFT");
        require(deposit.block + REWARD_DELAY <= block.number, "Must wait 24 hours");

        _deposits[tokenID].block = block.number;

        RewardToken rewardToken = RewardToken(tokenAddress);
        rewardToken.mintStakingRewards(msg.sender, 10 * 10 ** tokenDecimals);
    }

    function bulkCollectTokens(uint256[] calldata tokenIDs) external {
        uint256 tokensOwing = 0;

        // calculate total tokens owing in loop then execute single transfer
        uint256 arrayLength = tokenIDs.length;
        for (uint256 i = 0; i < arrayLength;) {
            Deposit memory deposit = _deposits[tokenIDs[i]];

            bool isOwner = deposit.depositer == msg.sender;
            bool isReady = deposit.block + REWARD_DELAY <= block.number;

            // use bools instead of require to avoid reverting the whole transaction
            if (isOwner && isReady) {
                tokensOwing += 10 * 10 ** tokenDecimals;
                _deposits[tokenIDs[i]].block = block.number;
            }
            unchecked {
                i++;
            }
        }
        RewardToken rewardToken = RewardToken(tokenAddress);
        rewardToken.mintStakingRewards(msg.sender, tokensOwing);
    }

    function withdrawNFT(uint256 tokenID) external {
        Deposit memory deposit = _deposits[tokenID];
        require(deposit.depositer == msg.sender, "Must be owner of NFT");

        delete _deposits[tokenID];
        ERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenID);

        // collect any outstanding tokens
        if (deposit.block + REWARD_DELAY <= block.number) {
            RewardToken rewardToken = RewardToken(tokenAddress);
            rewardToken.mintStakingRewards(msg.sender, 10 * 10 ** tokenDecimals);
        }
    }
}
