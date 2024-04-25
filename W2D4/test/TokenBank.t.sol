// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import '../src/BaseERC20WithCallback.sol';
import '../src/TokenBank.sol';

contract TokenBankTest is Test {


    TokenBank public tokenBank;
    BaseERC20WithCallback public baseERC20;

    function setUp() public {
        baseERC20 = new BaseERC20WithCallback();
        tokenBank = new TokenBank(address(baseERC20));
    }

    function test_Deposit() public {
        baseERC20.approve(address(tokenBank), 100);
        tokenBank.deposit(100);
        assertEq(tokenBank.balances(address(this)), 100);
    }

    function test_Withdraw() public {
        baseERC20.approve(address(tokenBank), 100);
        tokenBank.deposit(100);
        tokenBank.withdraw(100);
        assertEq(tokenBank.balances(address(this)), 0);
    }
    
}