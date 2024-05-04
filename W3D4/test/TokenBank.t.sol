// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenBank} from "../src/TokenBank.sol";
import {PermitERC20} from "../src/PermitERC20.sol";
import {SigUtil} from "../src/SigUtil.sol";

contract TokenBankTest is Test {
    TokenBank public tokenBank;
    PermitERC20 public token;
    SigUtil public sigUtil;

    function setUp() public {
        token = new PermitERC20();
        tokenBank = new TokenBank(address(token));
    }

    function test_permitDeposit() public {
        sigUtil = new SigUtil(token.DOMAIN_SEPARATOR());

        (address addrAlice, uint256 keyAlice) = makeAddrAndKey("alice");
        token.transfer(addrAlice, 100);

        vm.startPrank(addrAlice);

        SigUtil.Permit memory permit = SigUtil.Permit({
            owner: addrAlice,
            spender: address(tokenBank),
            value: 100,
            nonce: token.nonces(addrAlice),
            deadline: 1 hours
        });
        bytes32 digest = sigUtil.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(keyAlice, digest);

        tokenBank.permitDeposit(100, 1 hours, v, r, s);

        assertEq(token.balanceOf(addrAlice), 0);
        assertEq(token.balanceOf(address(tokenBank)), 100);
    }
}
