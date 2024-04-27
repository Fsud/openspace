// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {BaseERC20WithCallback} from '../src/BaseERC20WithCallback.sol';
import {MyERC721} from '../src/MyERC721.sol';
import {NftMarket} from '../src/NftMarket.sol';
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";


contract NftMarketTest is Test {

    BaseERC20WithCallback public token;
    MyERC721 public nft;
    NftMarket public nftMarket;

    event Transfer(address indexed from, address indexed to, uint256 tokenId);


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

    function test_ListWithoutApprove() public {
        console.log(address(this));
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector
            ,address(nftMarket),1));
        nftMarket.list(1, 100);
    }

    function test_BuyNFT() public {
        test_List();
        
        address alice = makeAddr("alice");
        token.transfer(alice, 1000);
        
        vm.startPrank(alice);
        token.approve(address(nftMarket), 100);

        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, address(this), 100); //token transfer event
        emit Transfer(address(nftMarket), alice, 1); //nft transfer event


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