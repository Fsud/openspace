// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./NftMarketV1.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @custom:oz-upgrades-from NftMarketV1
contract NftMarketV2 is NftMarketV1{
    

    using ECDSA for bytes32;

    using MessageHashUtils for bytes32;

    function permitList(uint256 tokenId, uint256 price, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(deadline> block.timestamp, "expire signiture");

        uint chainId = block.chainid;
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("NftMarketV2")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );  


        //List(address sender,uint256 tokenId, uint256 price, uint256 deadline)
        bytes32 hashStruct = keccak256(
        abi.encode(
            keccak256("List(address sender,uint256 tokenId, uint256 price, uint256 deadline)"),
            msg.sender,
            tokenId,
            price,
            deadline
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = hash.recover(v, r, s);
        require(signer == msg.sender, "invalid signature");

        list(tokenId, price);
    }

    function marketVersion() override public pure returns (uint8){
        return 2;
    }

}
