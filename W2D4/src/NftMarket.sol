// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC20} from './TokenBank.sol';
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) 
    external returns (bytes4);
}

interface TokenRecipient {
    function tokensReceived(address sender, uint256 value, bytes memory data) external returns (bool);
}

contract NftMarket is IERC721Receiver, TokenRecipient{

    IERC20 public immutable token;

    IERC721 public immutable nft;

    //nftid->价格
    mapping(uint256=>uint256) public prices;

    //nftid->卖家address
    mapping(uint256=>address) public listing;

    constructor(address _token, address _nft){
        token = IERC20(_token);
        nft = IERC721(_nft);
    }

    //用户需要先approve，再调用此接口, nft将被转移给market合约
    function list(uint256 tokenId, uint256 _price) public{
        require(nft.ownerOf(tokenId) == msg.sender,"not owner");
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        prices[tokenId] = _price;
        listing[tokenId] = msg.sender;
    }

    //用户购买
    function buyNFT(uint256 tokenId, uint256 amount) public{
        require(nft.ownerOf(tokenId) == address(this), "not owner");
        require(listing[tokenId]!= address(0), "not list");
        require(amount >= prices[tokenId], "amount less than price");
        token.transferFrom(msg.sender, listing[tokenId], prices[tokenId]);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        delete listing[tokenId];
        delete prices[tokenId];
    }

    //ERC20回调购买
    function tokensReceived(address sender, uint256 value, bytes memory data) external returns (bool){ 
        //校验，必须从ERC20合约回调过来
        require(msg.sender == address(token), "no auth");
        (uint256 tokenId) = abi.decode(data, (uint256));

        require(nft.ownerOf(tokenId) == address(this), "not owner");
        require(listing[tokenId]!= address(0), "not list");
        require(value >= prices[tokenId], "amount less than price");
        token.transfer(listing[tokenId], prices[tokenId]);
        nft.safeTransferFrom(address(this), sender, tokenId);
        delete listing[tokenId];
        delete prices[tokenId];
        return true;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) 
        external returns (bytes4){
        return this.onERC721Received.selector;
    }

    function price(uint256 tokenId) public view returns(uint256){
        return prices[tokenId];
    }

    function lister(uint256 tokenId) public view returns(address){
        return listing[tokenId];
    }
}
