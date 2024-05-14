// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./copy/NftMarket.sol";
import "./copy/PermitERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract AirdopMerkleNFTMarket is NftMarket {
    PermitERC20 permitERC20;

    bytes32 immutable merkleRoot;

    constructor(address _token, address _nft, bytes32 _merkleRoot) NftMarket(_token, _nft) {
        permitERC20 = PermitERC20(_token);
        merkleRoot = _merkleRoot;
    }

    //调用token的 permit 进行授权
    function permitPrePay(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        permitERC20.permit(msg.sender, address(this), amount, deadline, v, r, s);
    }

    //通过默克尔树验证白名单，半价购买，并利用 permitPrePay 的授权，转入 token 转出 NFT
    function claimNFT(uint256 amount, uint256 tokenId, bytes32[] calldata merkleProof) public {
        require(_isWhite(merkleProof, msg.sender), "merkle verify fail");

        require(nft.ownerOf(tokenId) == address(this), "not owner");
        require(listing[tokenId] != address(0), "not list");
        require(amount >= prices[tokenId] / 2, "amount less than price / 2");
        token.transferFrom(msg.sender, listing[tokenId], prices[tokenId] / 2);
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        delete listing[tokenId];
        delete prices[tokenId];
    }

    function multicall(bytes[] calldata datas) public returns (bytes[] memory results) {
        results = new bytes[](datas.length);
        for (uint256 i = 0; i < datas.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), datas[i]);
        }
        return results;
    }

    function _isWhite(bytes32[] calldata _merkleProof, address addr) private view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(_merkleProof, merkleRoot, node);
    }
}
