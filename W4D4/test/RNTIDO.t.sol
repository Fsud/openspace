// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {RNTIDO} from "../src/RNTIDO.sol";
import {BaseERC20} from "../src/copy/BaseERC20.sol";

contract RNTIDOTest is Test {
    RNTIDO rntido;
    BaseERC20 token;
    address owner;
    address alice;
    address bob;

    function setUp() public {
        owner = makeAddr("owner");
        vm.startPrank(owner);
        token = new BaseERC20("", "");
        rntido = new RNTIDO(token);
        token.transfer(address(rntido), 2000);
        rntido.initIDO(0.001 ether, 1 ether, 2 ether, block.timestamp + 1 hours);
        vm.stopPrank();

        alice = makeAddr("alice");
        vm.deal(alice, 100 ether);
        bob = makeAddr("bob");
        vm.deal(bob, 100 ether);
    }

    function test_buy_and_withdraw_hardCap() public {
        vm.deal(alice, 1 ether);
        vm.deal(bob, 2 ether);

        vm.prank(alice);
        rntido.buy{value: 1 ether}();
        vm.startPrank(bob);
        rntido.buy{value: 2 ether}();
        vm.stopPrank();

        vm.warp(block.timestamp + 2 hours);

        vm.prank(alice);
        rntido.withdrawToken();
        vm.prank(bob);
        rntido.withdrawToken();
        vm.prank(owner);
        rntido.withdrawOwner();

        assertEq(token.balanceOf(alice), 666);
        assertEq(token.balanceOf(bob), 1333);
        assertEq(alice.balance, 0.334 ether);
        assertEq(bob.balance, 0.667 ether);
        //assertEq(token.balanceOf(owner), 1);
        assertEq(owner.balance, 1.999 ether);
    }

    function test_buy_and_withdraw_softCap() public {
        vm.prank(alice);
        rntido.buy{value: 1 ether}();
        vm.prank(bob);
        rntido.buy{value: 1 ether}();

        vm.warp(block.timestamp + 2 hours);
        vm.prank(alice);
        rntido.withdrawToken();
        vm.prank(bob);
        rntido.withdrawToken();
        vm.prank(owner);
        rntido.withdrawOwner();

        assertEq(token.balanceOf(alice), 1000);
        assertEq(token.balanceOf(bob), 1000);
        assertEq(owner.balance, 2 ether);
    }

    function test_buy_and_refund() public {
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);

        vm.prank(alice);
        rntido.buy{value: 0.2 ether}();
        vm.prank(bob);
        rntido.buy{value: 0.2 ether}();
        vm.prank(bob);
        vm.expectRevert("IDO has not ended yet");
        rntido.refund();

        vm.warp(block.timestamp + 2 hours);
        vm.prank(alice);
        rntido.refund();
        vm.prank(bob);
        rntido.refund();
        vm.prank(owner);
        rntido.refundOwner();

        assertEq(alice.balance, 1 ether);
        assertEq(bob.balance, 1 ether);
        assertEq(token.balanceOf(owner), 2000);
    }
}
