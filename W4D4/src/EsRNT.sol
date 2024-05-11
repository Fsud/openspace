// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EsRNT is ERC20, Ownable {
    address public stakeContract;

    event Mint(address indexed to, uint256 amount);

    constructor(string memory name, string memory symbol, address initialOwner)
        ERC20(name, symbol)
        Ownable(initialOwner)
    {}

    function setStakeContract(address _stakeContract) public onlyOwner {
        stakeContract = _stakeContract;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == stakeContract || msg.sender == owner(), "no auth to mint");
        _mint(to, amount);
        emit Mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
