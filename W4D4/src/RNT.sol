// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RNT is ERC20, Ownable {
    address public stakeContract;

    event Mint(address indexed to, uint256 amount);

    constructor() ERC20("RNT", "RNT") Ownable(msg.sender) {}

    function setStakeContract(address _stakeContract) public onlyOwner {
        stakeContract = _stakeContract;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == stakeContract || msg.sender == owner(), "no auth to mint");
        _mint(to, amount);
        emit Mint(to, amount);
    }
}
