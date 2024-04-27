// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import '../src/BaseERC20WithCallback.sol';
import '../src/TokenBank.sol';
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";


contract TokenBankTest is Test {


    TokenBank public tokenBank;
    BaseERC20WithCallback public baseERC20;

    event Deposit(address indexed user, uint256 value);

    event Withdraw(address indexed user, uint256 value);


    function setUp() public {
        baseERC20 = new BaseERC20WithCallback();
        tokenBank = new TokenBank(address(baseERC20));
    }

    function test_Deposit() public {
        baseERC20.approve(address(tokenBank), 100);

        vm.expectEmit(true, false,false,true);
        emit Deposit(address(this), 100);

        tokenBank.deposit(100);
        assertEq(tokenBank.balances(address(this)), 100);
    }

    function test_DepositWithoutApprove() public {
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        tokenBank.deposit(100);

    }

    function test_Withdraw() public {
        baseERC20.approve(address(tokenBank), 100);
        tokenBank.deposit(100);

        vm.expectEmit(true, false,false,true);
        emit Withdraw(address(this), 100);
        tokenBank.withdraw(100);
        assertEq(tokenBank.balances(address(this)), 0);
    }
    
}