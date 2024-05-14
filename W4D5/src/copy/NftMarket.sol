// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

contract NftMarket is Nonces, IERC721Receiver {
    IERC20 public immutable token;

    IERC721 public immutable nft;

    //nftid->价格
    mapping(uint256 => uint256) public prices;

    //nftid->卖家address
    mapping(uint256 => address) public listing;

    address public admin;

    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    constructor(address _token, address _nft) {
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

    function price(uint256 tokenId) public view returns (uint256) {
        return prices[tokenId];
    }

    function lister(uint256 tokenId) public view returns (address) {
        return listing[tokenId];
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    function permitBuy(uint256 nonce, bytes calldata signature, uint256 tokenId, uint256 amount) public {
        _useCheckedNonce(msg.sender, nonce);
        //业务参数打包取hash
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, nonce));
        hash = hash.toEthSignedMessageHash();
        //使用hash还原签名，得到签名地址
        address signAddr = hash.recover(signature);
        //签名地址正确，是有效签名
        require(signAddr == admin, "error signiture");

        _useNonce(msg.sender);

        buyNFT(tokenId, amount);
    }
}
