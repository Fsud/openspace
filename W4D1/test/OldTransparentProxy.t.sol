// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "../src/copy/BaseERC20.sol";
import "../src/copy/MyERC721.sol";
import "../src/NftMarketV1.sol";
import "../src/NftMarketV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../src/MyTransparentProxy.sol";
import {Test, console} from "forge-std/Test.sol";

contract NftMarketTest is Test {
    NftMarketV1 public nftMarketV1;
    NftMarketV2 public nftMarketV2;
    MyERC721 public nft;
    BaseERC20 token;
    address admin;
    uint256 adminKey;

    address alice;
    uint256 aliceKey;

    address proxyAdmin;
    MyTransparentProxy proxy;

    using ECDSA for bytes32;


    function setUp() public {
        (admin, adminKey) = makeAddrAndKey("admin");
        (alice, aliceKey) = makeAddrAndKey("alice");
        console.log("admin is:", admin);

        vm.startPrank(admin);
        token = new BaseERC20("TEST","TEST");
        nft = new MyERC721();
        nftMarketV1 = new NftMarketV1();

        proxy = new MyTransparentProxy(address(nftMarketV1), 
            admin, abi.encodeWithSelector(NftMarketV1.initialize.selector, address(token),address(nft))); 

        proxyAdmin = proxy.getAdmin();
        console.log("proxyAdmin is:", proxyAdmin);
        token.transfer(alice, 100);
        nft.mint(alice, ""); //token id = 1
        nft.mint(alice, ""); //token id = 2
        nft.mint(alice, ""); //token id = 3

        vm.stopPrank();
    }

    function test_proxySet() public {
        vm.startPrank(alice);
        nft.approve(address(proxy), 1);
        (bool success,) = 
            address(proxy).call(abi.encodeWithSelector(NftMarketV1.list.selector, 1, 100));
        assertEq(success, true);
        (,bytes memory data) = 
            address(proxy).call(abi.encodeWithSelector(NftMarketV1.lister.selector, 1));
        assertEq(abi.decode(data, (address)), alice);
        vm.stopPrank();
    }

    function test_proxyUpgrade() public {
        test_proxySet();
        vm.startPrank(admin);
        nftMarketV2 = new NftMarketV2();

        ProxyAdmin(proxyAdmin).upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(nftMarketV2),new bytes(0));
        vm.stopPrank();

        vm.startPrank(alice);
        nft.approve(address(proxy), 2);
        (bool success,) = 
            address(proxy).call(abi.encodeWithSelector(NftMarketV1.list.selector, 2, 100));
        assertEq(success, true);
        (,bytes memory data) = 
            address(proxy).call(abi.encodeWithSelector(NftMarketV1.lister.selector, 1));
        assertEq(abi.decode(data, (address)), alice);
        
        NftMarketV2 v2 = NftMarketV2(address(proxy));
        v2.lister(2);
        assertEq(v2.marketVersion(), 2);

        vm.stopPrank();
    }

    function test_permitList() public {

        test_proxyUpgrade();
        NftMarketV2 v2 = NftMarketV2(address(proxy));

        vm.startPrank(alice);
        nft.setApprovalForAll(address(v2), true);

        uint chainId = block.chainid;
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("NftMarketV2")),
                keccak256(bytes("1")),
                chainId,
                address(v2)
            )
        );  


        //List(address sender,uint256 tokenId, uint256 price, uint256 deadline)
        bytes32 hashStruct = keccak256(
        abi.encode(
            keccak256("List(address sender,uint256 tokenId, uint256 price, uint256 deadline)"),
            alice,
            3,
            100,
            block.timestamp + 1 hours
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, hash);
        v2.permitList(3, 100, block.timestamp + 1 hours, v, r, s);

        assertEq(v2.lister(3), alice);

    }

}