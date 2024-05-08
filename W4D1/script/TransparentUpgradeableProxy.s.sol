// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/copy/BaseERC20.sol";
import "../src/copy/MyERC721.sol";
import "../src/NftMarketV1.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Upgrades,Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract TransparentUpgradeableProxyScript is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.envAddress("ADDRESS");

        
        address token = address(0x552DFF72A5caC04bDe5CA0E5C6D33b9bA3AF115b);
        address nft = address(0xB58e257506bAE4a6b3Ac6b369Ff4B6fFa7BE7332);

        vm.startBroadcast(deployerPrivateKey);

        address proxy = Upgrades.deployTransparentProxy(
            "NftMarketV1.sol",
            admin,
            abi.encodeCall(NftMarketV1.initialize, (token, nft)));

        NftMarketV1 nftMarketV1 = NftMarketV1(proxy);


        Options memory optsUpdate;
        optsUpdate.referenceContract = "NftMarketV1.sol";

        Upgrades.upgradeProxy(proxy, "NftMarketV2.sol", "",optsUpdate,address(admin));


        
        vm.stopBroadcast();

    }
}