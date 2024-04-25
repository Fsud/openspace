// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {BaseERC20WithCallback} from '../src/BaseERC20WithCallback.sol';
import {MyERC721} from '../src/MyERC721.sol';
import {NftMarket} from '../src/NftMarket.sol';

contract NftMarketTest is Test {

    BaseERC20WithCallback public token;
    MyERC721 public nft;
    NftMarket public nftMarket;

    function setUp() public {
        token = new BaseERC20WithCallback();
        nft = new MyERC721();
        nft.mint(address(this), "ipfs://QmSnq6izJgHpP988D3qHosXQMXW1r7wJpV8F88cgQaZ7vc/NFT1.jpg");
        nftMarket = new NftMarket(address(token), address(nft));
    }

    function test_List() public {
        nft.approve(address(nftMarket), 1);
        nftMarket.list(1, 100);
        assertEq(nftMarket.price(1), 100);
        assertEq(nftMarket.lister(1), address(this));
    }

    function test_BuyNFT() public {
        test_List();
        
        address alice = address(0x1);
        token.transfer(alice, 1000);
        
        vm.startPrank(alice);
        token.approve(address(nftMarket), 100);
        nftMarket.buyNFT(1, 100);
        assertEq(nft.ownerOf(1), alice);
    }

    function test_TokensReceived() public {
        test_List();
        
        address alice = address(0x1);
        token.transfer(alice, 1000);
        
        vm.startPrank(alice);
        require(token.balanceOf(alice) >= 1000, "eds balance");
        token.transferCallback(address(nftMarket), 100, abi.encode(1));
        assertEq(nft.ownerOf(1), alice);
    }

}