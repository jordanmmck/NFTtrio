// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/NFTtrio.sol";

contract NFTtrioTest is Test {
    NFTtrio public nfttrio;

    address public alice = address(0x1);
    address public jordan = address(0x34);

    function setUp() public {
        bytes32 merkleRoot = 0x897d6714686d83f84e94501e5d6f0f38c94b75381b88d1de3878b4f3d2d5014a;
        vm.prank(address(0x99));
        nfttrio = new NFTtrio(merkleRoot, jordan);
    }

    function testValidDiscountProof() public {
        bytes32[] memory proof = new bytes32[](3);
        proof[0] = 0x50bca9edd621e0f97582fa25f616d475cabe2fd783c8117900e5fed83ec22a7c;
        proof[1] = 0x8138140fea4d27ef447a72f4fcbc1ebb518cca612ea0d392b695ead7f8c99ae6;
        proof[2] = 0x9005e06090901cdd6ef7853ac407a641787c28a78cb6327999fc51219ba3c880;

        uint256 index = 0;
        vm.deal(alice, 0.05 ether);
        vm.prank(alice);
        nfttrio.mintWithDiscount{value: 0.05 ether}(proof, index);

        assertEq(nfttrio.balanceOf(alice), 1);
    }

    function testInvalidDiscountProof() public {
        bytes32[] memory proof = new bytes32[](3);
        proof[0] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        proof[1] = 0x8138140fea4d27ef447a72f4fcbc1ebb518cca612ea0d392b695ead7f8c99ae6;
        proof[2] = 0x9005e06090901cdd6ef7853ac407a641787c28a78cb6327999fc51219ba3c880;

        uint256 index = 0;
        vm.deal(alice, 0.05 ether);
        vm.prank(alice);
        vm.expectRevert("Invalid proof");
        nfttrio.mintWithDiscount{value: 0.05 ether}(proof, index);
    }

    function testNormalMint() public {
        vm.deal(alice, 0.1 ether);
        vm.prank(alice);
        nfttrio.mint{value: 0.1 ether}();
    }

    function testExceedMaxMints() public {
        vm.startPrank(alice);

        vm.deal(alice, 1 ether);
        nfttrio.mint{value: 0.1 ether}();
        nfttrio.mint{value: 0.1 ether}();
        vm.expectRevert("Only two NFTs per address");
        nfttrio.mint{value: 0.1 ether}();

        vm.stopPrank();
    }

    function testAttemptDoubleDiscount() public {
        bytes32[] memory proof = new bytes32[](3);
        proof[0] = 0x50bca9edd621e0f97582fa25f616d475cabe2fd783c8117900e5fed83ec22a7c;
        proof[1] = 0x8138140fea4d27ef447a72f4fcbc1ebb518cca612ea0d392b695ead7f8c99ae6;
        proof[2] = 0x9005e06090901cdd6ef7853ac407a641787c28a78cb6327999fc51219ba3c880;

        uint256 index = 0;
        vm.deal(alice, 0.05 ether);
        vm.prank(alice);
        nfttrio.mintWithDiscount{value: 0.05 ether}(proof, index);

        vm.deal(alice, 0.05 ether);
        vm.prank(alice);
        vm.expectRevert("Discount already used");
        nfttrio.mintWithDiscount{value: 0.05 ether}(proof, index);
    }

    function testWithdrawRoyalties() public {
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        nfttrio.mint{value: 0.1 ether}();
        nfttrio.mint{value: 0.1 ether}();
        vm.stopPrank();

        assertEq(address(nfttrio).balance, 0.2 ether);

        vm.prank(jordan);
        nfttrio.withdrawRoyalties();

        assertEq(address(jordan).balance, 0.2 ether * 0.025);
    }

    function testWithdrawReserves() public {
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        nfttrio.mint{value: 0.1 ether}();
        nfttrio.mint{value: 0.1 ether}();
        vm.stopPrank();

        assertEq(address(nfttrio).balance, 0.2 ether);

        vm.prank(address(0x99));
        nfttrio.withdrawReserves();

        assertEq(address(0x99).balance, 0.2 ether * (1 - 0.025));
    }

    function testTransferOwnership() public {
        vm.startPrank(alice);
        vm.deal(alice, 1 ether);
        nfttrio.mint{value: 0.1 ether}();
        nfttrio.mint{value: 0.1 ether}();
        vm.stopPrank();

        assertEq(nfttrio.owner(), address(0x99));

        vm.prank(address(0x99));
        nfttrio.transferOwnership(address(0x88));
        vm.prank(address(0x88));
        nfttrio.acceptOwnership();

        assertEq(nfttrio.owner(), address(0x88));

        vm.prank(address(0x88));
        nfttrio.withdrawReserves();
        assertEq(address(0x88).balance, 0.2 ether * (1 - 0.025));
    }
}
