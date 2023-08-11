// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";

import "../src/NFTtrio.sol";
import "../src/Staking.sol";
import "../src/RewardToken.sol";

contract NFTStaking is Test {
    NFTtrio public nfttrio;
    Staking public staking;
    RewardToken public rewardToken;

    uint256 public constant REWARD_DELAY = 17280;

    address public alice = address(0x1);
    address public jordan = address(0x34);
    address public admin = address(0x99);

    function setUp() public {
        vm.startPrank(admin);

        nfttrio = new NFTtrio(0, jordan);
        rewardToken = new RewardToken();
        staking = new Staking(address(nfttrio), address(rewardToken));
        rewardToken.setStakingAddress(address(staking));

        vm.stopPrank();
    }

    function testSimpleStake() public {
        // mint NFT
        vm.deal(alice, 0.1 ether);
        vm.prank(alice);
        nfttrio.mint{value: 0.1 ether}();
        assertEq(nfttrio.balanceOf(alice), 1);

        // stake NFT by sending to staking contract
        vm.prank(alice);
        nfttrio.safeTransferFrom(alice, address(staking), 0);
        assertEq(nfttrio.balanceOf(alice), 0);
    }

    function testWithdraw() public {
        // mint NFT
        vm.deal(alice, 0.1 ether);
        vm.prank(alice);
        nfttrio.mint{value: 0.1 ether}();
        assertEq(nfttrio.balanceOf(alice), 1);

        // stake NFT by sending to staking contract
        vm.prank(alice);
        nfttrio.safeTransferFrom(alice, address(staking), 0);
        assertEq(nfttrio.balanceOf(alice), 0);

        // withdraw NFT
        vm.prank(alice);
        staking.withdrawNFT(0);
        assertEq(nfttrio.balanceOf(alice), 1);
    }

    function testWithdrawNotOwner() public {
        // mint NFT
        vm.deal(alice, 0.1 ether);
        vm.prank(alice);
        nfttrio.mint{value: 0.1 ether}();
        assertEq(nfttrio.balanceOf(alice), 1);

        // stake NFT by sending to staking contract
        vm.prank(alice);
        nfttrio.safeTransferFrom(alice, address(staking), 0);
        assertEq(nfttrio.balanceOf(alice), 0);

        // withdraw NFT
        vm.prank(jordan);
        vm.expectRevert("Must be owner of NFT");
        staking.withdrawNFT(0);
    }

    function testWithdrawPlusRewards() public {
        // mint NFT
        vm.deal(alice, 0.1 ether);
        vm.prank(alice);
        nfttrio.mint{value: 0.1 ether}();
        assertEq(nfttrio.balanceOf(alice), 1);

        // stake NFT by sending to staking contract
        vm.prank(alice);
        nfttrio.safeTransferFrom(alice, address(staking), 0);
        assertEq(nfttrio.balanceOf(alice), 0);

        vm.roll(REWARD_DELAY + 1);

        // withdraw NFT
        vm.prank(alice);
        staking.withdrawNFT(0);
        assertEq(nfttrio.balanceOf(alice), 1);
        assertEq(rewardToken.balanceOf(alice), 10 * 10 ** 18);
    }

    function testWithdrawAfterDuration() public {
        // mint NFT
        vm.deal(alice, 0.1 ether);
        vm.prank(alice);
        nfttrio.mint{value: 0.1 ether}();
        assertEq(nfttrio.balanceOf(alice), 1);

        // stake NFT by sending to staking contract
        vm.prank(alice);
        nfttrio.safeTransferFrom(alice, address(staking), 0);
        assertEq(nfttrio.balanceOf(alice), 0);

        // withdraw NFT
        vm.roll(REWARD_DELAY + 1);
        vm.prank(alice);
        staking.withdrawNFT(0);
        assertEq(nfttrio.balanceOf(alice), 1);
        assertEq(rewardToken.balanceOf(alice), 10 * 10 ** 18);
    }

    function testStakeAndProfit() public {
        // mint NFT
        vm.deal(alice, 0.1 ether);
        vm.prank(alice);
        nfttrio.mint{value: 0.1 ether}();
        assertEq(nfttrio.balanceOf(alice), 1);

        // stake NFT by sending to staking contract
        vm.prank(alice);
        nfttrio.safeTransferFrom(alice, address(staking), 0);
        assertEq(nfttrio.balanceOf(alice), 0);
        assertEq(rewardToken.balanceOf(alice), 0);

        // advance block time forward 24 hours
        vm.roll(REWARD_DELAY + 1);

        // withdraw reward tokens
        vm.prank(alice);
        staking.collectTokens(0);
        assertEq(rewardToken.balanceOf(alice), 10 * 10 ** 18);
    }

    function testStakeAndProfitTwice() public {
        // mint NFT
        vm.deal(alice, 0.1 ether);
        vm.prank(alice);
        nfttrio.mint{value: 0.1 ether}();
        assertEq(nfttrio.balanceOf(alice), 1);

        // stake NFT by sending to staking contract
        vm.prank(alice);
        nfttrio.safeTransferFrom(alice, address(staking), 0);
        assertEq(nfttrio.balanceOf(alice), 0);
        assertEq(rewardToken.balanceOf(alice), 0);

        // advance block time forward 24 hours
        vm.roll(REWARD_DELAY + 1);
        vm.prank(alice);
        // withdraw reward tokens
        staking.collectTokens(0);
        assertEq(rewardToken.balanceOf(alice), 10 * 10 ** 18);

        // advance block time another 24 hours
        vm.roll((REWARD_DELAY + 1) * 2);
        vm.prank(alice);
        // withdraw reward tokens
        staking.collectTokens(0);
        assertEq(rewardToken.balanceOf(alice), 20 * 10 ** 18);
    }

    function testCollectTokensFailNotOwner() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);
        nfttrio.mint{value: 0.1 ether}();
        nfttrio.safeTransferFrom(alice, address(staking), 0);
        vm.stopPrank();

        vm.roll(REWARD_DELAY + 1);
        vm.prank(jordan);
        vm.expectRevert("Must be owner of NFT");
        staking.collectTokens(0);
    }

    function testCollectTokensFailMustWait() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);
        nfttrio.mint{value: 0.1 ether}();
        nfttrio.safeTransferFrom(alice, address(staking), 0);
        vm.stopPrank();

        vm.roll(REWARD_DELAY - 1000);
        vm.prank(alice);
        vm.expectRevert("Must wait 24 hours");
        staking.collectTokens(0);
    }

    function testBulkCollectTokens() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        nfttrio.mint{value: 0.1 ether}();
        vm.prank(alice);
        nfttrio.mint{value: 0.1 ether}();

        vm.prank(alice);
        nfttrio.safeTransferFrom(alice, address(staking), 0);
        vm.prank(alice);
        nfttrio.safeTransferFrom(alice, address(staking), 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;

        vm.roll(REWARD_DELAY + 1);
        vm.prank(alice);
        staking.bulkCollectTokens(tokenIds);
        assertEq(rewardToken.balanceOf(alice), 20 * 10 ** 18);
    }

    function testBulkCollectTokens1NotReady() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);
        nfttrio.mint{value: 0.1 ether}();
        nfttrio.mint{value: 0.1 ether}();

        nfttrio.safeTransferFrom(alice, address(staking), 0);
        vm.roll(REWARD_DELAY - 1000);
        nfttrio.safeTransferFrom(alice, address(staking), 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;

        vm.roll(REWARD_DELAY + 1);
        staking.bulkCollectTokens(tokenIds);
        assertEq(rewardToken.balanceOf(alice), 10 * 10 ** 18);
    }

    function testBulkCollectTokensNotOwner() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);
        nfttrio.mint{value: 0.1 ether}();
        nfttrio.mint{value: 0.1 ether}();

        nfttrio.safeTransferFrom(alice, address(staking), 0);
        nfttrio.safeTransferFrom(alice, address(staking), 1);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        vm.stopPrank();

        vm.roll(REWARD_DELAY + 1);
        vm.prank(jordan);
        staking.bulkCollectTokens(tokenIds);
        assertEq(rewardToken.balanceOf(jordan), 0);
    }
}
