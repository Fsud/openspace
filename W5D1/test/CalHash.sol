pragma solidity ^0.8.25;

import "../src/uni-core/UniswapV2Pair.sol";
import {Test, console2} from "forge-std/Test.sol";

contract CalHash is Test {
    function setUp() public {}

    function test_getInitHash() public returns (bytes32) {
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 result = (keccak256(abi.encodePacked(bytecode)));
        return result;
    }
}
