// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "../src/copy/BaseERC20.sol";
import "../src/copy/MyERC721.sol";
import "../src/NftMarketV1.sol";
import "../src/NftMarketV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


import "../src/MyTransparentProxy.sol";
import {Test, console} from "forge-std/Test.sol";
import { Upgrades, Options } from "openzeppelin-foundry-upgrades/Upgrades.sol";


contract NftMarketTest is Test {
    NftMarketV1 public nftMarketV1;
    MyERC721 public nft;
    BaseERC20 token;
    address admin;
    uint256 adminKey;

    address alice;
    uint256 aliceKey;

    address proxyAdmin;

    

    function setUp() public {
        (admin, adminKey) = makeAddrAndKey("admin");

        nft = new MyERC721();
        token = new BaseERC20("MyERC20","MyERC20");
    }

    function test_ProxyUpgradeNew() public {
        //使用之前已部署的两个地址

        Options memory opts;
        opts.unsafeSkipAllChecks = true;

        address proxy = Upgrades.deployTransparentProxy(
            "NftMarketV1.sol",
            admin,
            abi.encodeCall(NftMarketV1.initialize, (address(token), address(nft))),
            opts
            );

        NftMarketV1 proxyMarket = NftMarketV1(proxy);
        console.log("v1v1v1v1v1vv",proxyMarket.marketVersion());
        assertEq(proxyMarket.marketVersion(), 1);
        nft.mint(address(this), "");
        nft.approve(proxy, 1);
        proxyMarket.list(1, 100);

        Options memory optsUpdate;
        optsUpdate.referenceContract = "NftMarketV1.sol";
        Upgrades.upgradeProxy(proxy, "NftMarketV2.sol", "",optsUpdate,address(admin));
        proxyMarket = NftMarketV2(proxy);
        console.log("v2v2v2v2v2vv",proxyMarket.marketVersion());
        assertEq(proxyMarket.marketVersion(), 2);
        //验证升级后，合约状态（挂单状态）不变
        assertEq(proxyMarket.lister(1), address(this));


    }

}