// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

contract MyWallet {
    string public name;
    mapping(address => bool) private approved;
    address public owner;

    modifier auth() {
        // require(msg.sender == owner, "Not authorized");
        assembly {
            if iszero(eq(sload(owner.slot), caller())) { revert(0, 0) }
        }
        _;
    }

    constructor(string memory _name) {
        name = _name;
        owner = msg.sender;
    }

    function transferOwernship(address _addr) public auth {
        require(_addr != address(0), "New owner is the zero address");
        require(owner != _addr, "New owner is the same as the old owner");

        //owner = _addr;
        assembly {
            sstore(owner.slot, _addr)
        }
    }
}
