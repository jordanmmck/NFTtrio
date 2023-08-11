// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";
import "../src/RewardToken.sol";
import {console} from "forge-std/Test.sol";

contract RewardTokenTest is Test {
    RewardToken public rewardToken;

    address public alice = address(0x1);
    address public jordan = address(0x34);

    function setUp() public {
        vm.prank(jordan);
        rewardToken = new RewardToken();
    }

    function testSetStakingAddress() public {
        vm.prank(jordan);
        rewardToken.setStakingAddress(jordan);
        assertEq(rewardToken.stakingAddress(), jordan);
    }

    function testSetStakingAddressNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        rewardToken.setStakingAddress(jordan);
    }

    function testSetStakingAddressFailZeroAddr() public {
        vm.prank(jordan);
        vm.expectRevert("Zero address");
        rewardToken.setStakingAddress(address(0));
    }

    function testMintStakingRewardsFail() public {
        vm.prank(jordan);
        vm.expectRevert("Only staking contract can mint");
        rewardToken.mintStakingRewards(address(0), 0);
    }
}
