// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {NftMarket} from "../src/NftMarket.sol";
import {BaseERC20WithCallback} from "../src/BaseERC20WithCallback.sol";
import {MyERC721} from "../src/MyERC721.sol";


contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        BaseERC20WithCallback token = new BaseERC20WithCallback();
        MyERC721 nft = new MyERC721();

        new NftMarket(address(token), address(nft));
        vm.stopBroadcast();
    }
}
