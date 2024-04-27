// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BaseERC20WithCallback} from "../src/BaseERC20WithCallback.sol";
import "../src/TokenBankWithCallback.sol";

contract BaseERC20WithCallbackTest is Test {
    BaseERC20WithCallback public baseERC20;
    address alice = makeAddr("alice");
    TokenBankWithCallback public tokenBank;

    event Transfer(address indexed from, address indexed to, uint256 value);


    function setUp() public {
        baseERC20 = new BaseERC20WithCallback();
        tokenBank = new TokenBankWithCallback(address(baseERC20));
    }

    function test_Transfer() public {
        baseERC20.transfer(alice, 100);
        assertEq(baseERC20.balanceOf(alice), 100);
    }

    function test_Approve() public {
        baseERC20.approve(alice, 300);
        assertEq(baseERC20.allowance(address(this), alice), 300);
    }

    function test_TransferFrom() public {
        address bob = makeAddr("bob");
        baseERC20.transfer(bob, 100);
        vm.prank(bob);
        baseERC20.approve(alice, 100);
        vm.startPrank(alice);

        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, alice, 100);

        baseERC20.transferFrom(bob, alice, 100);
        assertEq(baseERC20.balanceOf(alice), 100);
        assertEq(baseERC20.balanceOf(bob), 0);
    }

    function test_TransferCallback() public {
        baseERC20.transferCallback(address(tokenBank), 100, "0x1234");
        assertEq(tokenBank.bankBalance(address(this)), 100);
    }

    function test_TransferWithoutApprove() public {
        address bob = makeAddr("bob");
        baseERC20.transfer(bob, 100);
        vm.prank(alice);
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        baseERC20.transferFrom(bob, alice, 100);
    }


    function test_TransferTooMuch() public {
        address bob = makeAddr("bob");
        baseERC20.transfer(bob, 100);
        vm.startPrank(bob);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        baseERC20.transfer(alice, 101);
    }
}
