// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MyWallet} from "../src/MyWallet.sol";

contract MyWalletTest is Test {
    MyWallet public myWallet;

    function setUp() public {
        myWallet = new MyWallet("wallet");
    }

    function test_transferOwernship() public {
        address alice = makeAddr("alice");
        myWallet.transferOwernship(alice);
        assertEq(myWallet.owner(), alice);
    }
}
