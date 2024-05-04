// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract PermitERC20 is ERC20Permit {
    constructor() ERC20Permit("PermitERC20") ERC20("PermitERC20", "PERC20") {
        _mint(msg.sender, 1e18);
    }

}
