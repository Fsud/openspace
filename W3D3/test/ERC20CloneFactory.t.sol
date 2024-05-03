// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import "../src/ERC20CloneFactory.sol";
import "../src/MiniERC20.sol";

contract ERC20CloneFactoryTest is Test {
    ERC20CloneFactory public factory;

    MiniERC20 public erc20;

    event Clone(address indexed sender, address token);

    address admin = makeAddr("admin");

    function setUp() public {
        vm.prank(admin);
        factory = new ERC20CloneFactory(5);
    }

    function test_deployInscription() public returns (address) {
        vm.expectEmit(true, false, false, false);
        emit Clone(address(this), makeAddr(""));
        address copy = factory.deployInscription("TEST1", 1e22, 100 * 1e18, 0.1 ether);

        Inscription memory inscription = factory.getInscription(copy);
        assertEq(inscription.token, copy);
        assertEq(inscription.symbol, "TEST1");
        assertEq(inscription.minted, 0);
        assertEq(inscription.owner, address(this));
        assertEq(MiniERC20(copy).balanceOf(address(factory)), 1e22); //铭文erc20全部转移给工厂合约
        
        address copy2 = factory.deployInscription("TEST2", 1e22, 100 * 1e18, 0.1 ether);
        assertNotEq(copy, copy2);
        return copy;
    }

    function test_mintInscription() public {
        address alice = makeAddr("alice"); //token owner
        address bob = makeAddr("bob"); //minter
        deal(bob, 0.1 ether);
        vm.prank(alice);
        address copy = factory.deployInscription("TEST", 1e22, 100 * 1e18, 0.1 ether);

        vm.startPrank(bob);
        factory.mintInscription{value: 0.1 ether}(copy);
        Inscription memory inscription = factory.getInscription(copy);
        assertEq(inscription.minted, 100 * 1e18);
        assertEq(MiniERC20(copy).balanceOf(bob), 100 * 1e18); //代币分配正确

        assertEq(alice.balance, 0.095 ether); // token owner正确
        assertEq(admin.balance, 0.005 ether); // 管理员正确

    }

    function test_mintRevert() public {
        vm.prank(makeAddr("alice"));
        address copy = factory.deployInscription("TEST", 1e20, 100 * 1e18, 0.1 ether);
        address bob = makeAddr("bob"); //minter
        deal(bob, 1 ether);
        vm.startPrank(bob);
        factory.mintInscription{value: 0.1 ether}(copy);

        vm.expectRevert("mint end");
        factory.mintInscription{value: 0.1 ether}(copy);

    }
}
