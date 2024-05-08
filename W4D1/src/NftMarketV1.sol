// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./copy/IERC721Receiver.sol";

//与之前作业相比，去掉了构造函数
contract NftMarketV1 is Initializable,IERC721Receiver {
    IERC20 public token;

    IERC721 public nft;

    //nftid->价格
    mapping(uint256 => uint256) public prices;

    //nftid->卖家address
    mapping(uint256 => address) public listing;

    address public admin;

    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;


    function initialize(address _token, address _nft) initializer public {
        token = IERC20(_token);
        nft = IERC721(_nft);
        admin = msg.sender;
    }

    //用户需要先approve，再调用此接口, nft将被转移给market合约
    function list(uint256 tokenId, uint256 _price) public {
        require(nft.ownerOf(tokenId) == msg.sender, "not owner");
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        prices[tokenId] = _price;
        listing[tokenId] = msg.sender;
    }

    //用户购买
    function buyNFT(uint256 tokenId, uint256 amount) internal {
        require(nft.ownerOf(tokenId) == address(this), "not owner");
        require(listing[tokenId] != address(0), "not list");
        require(amount >= prices[tokenId], "amount less than price");
        token.transferFrom(msg.sender, listing[tokenId], prices[tokenId]);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        delete listing[tokenId];
        delete prices[tokenId];
    }

    function lister(uint256 tokenId) public view returns (address) {
        return listing[tokenId];
    }

    function marketVersion() virtual public pure returns (uint8){
        return 1;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
}
