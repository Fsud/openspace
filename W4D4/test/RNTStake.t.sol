// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {RNTStake} from "../src/RNTStake.sol";
import {RNT} from "../src/RNT.sol";
import {EsRNT} from "../src/EsRNT.sol";

contract RNTStakeTest is Test {
    address admin;
    RNTStake rntStake;
    RNT rnt;
    EsRNT esRNT;

    function setUp() public {
        admin = makeAddr("admin");
        vm.startPrank(admin);
        rnt = new RNT();
        esRNT = new EsRNT("esRNT", "esRNT", admin);
        rntStake = new RNTStake(rnt, esRNT);
        rnt.setStakeContract(address(rntStake));
        esRNT.setStakeContract(address(rntStake));
        rnt.mint(admin, 200 * 1e18);
        vm.stopPrank();
    }

    function test_stake() public {
        vm.startPrank(admin);
        rnt.approve(address(rntStake), 200 * 1e18);
        rntStake.stake(100 * 1e18);
        vm.warp(block.timestamp + 1 days);
        rntStake.stake(100 * 1e18);
        vm.warp(block.timestamp + 1 days);
        rntStake.unstake(200 * 1e18);
        assertEq(rnt.balanceOf(admin), 200 * 1e18);
    }

    function test_claim() public {
        test_stake();
        rntStake.claim();
        uint256 speed = rntStake.mintSpeedPersecond();
        assertEq(esRNT.balanceOf(admin), speed * 2 days * 100 + speed * 1 days * 100);
    }

    function test_esTokenLockAndBurn() public {
        test_claim();
        esRNT.approve(address(rntStake), 200 * 1e18);
        rntStake.esTokenLock(100 * 1e18);
        vm.warp(block.timestamp + 1 days);
        rntStake.esTokenLock(50 * 1e18);
        vm.warp(block.timestamp + 1 days);
        rntStake.esTokenLock(50 * 1e18);
        vm.warp(block.timestamp + 1 days);
        rntStake.esTokenBurn();
        uint256 speed = rntStake.esTokenSpeedPersecond();
        //100个币存了3天，50个币存了2天，50个币存了1天
        assertEq(rnt.balanceOf(admin)- 200 * 1e18, speed * 3 days * 100 + speed * 2 days * 50 + speed * 1 days * 50);
    }
}
