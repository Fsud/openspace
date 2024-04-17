// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Counter {
    uint public counter;
    address public owner;
    constructor() {
        owner = msg.sender;
        counter = 0;
    }

    function add(uint x) public {
        counter+=x;
    }

    function get() public view returns (uint){
        return counter;
    }
}