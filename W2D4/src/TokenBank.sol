// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenBank {

    IERC20 public token;

    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 value);

    event Withdraw(address indexed user, uint256 value);

    constructor(address _token){
        token = IERC20(_token);
    }

    //先调用token合约的approve，再调用此函数，才能成功
    function deposit(uint256 value) public{
        balances[msg.sender] += value;
        token.transferFrom(msg.sender,address(this),value);
        emit Deposit(msg.sender, value);
    }

    function withdraw(uint256 value) public{
        require(balances[msg.sender] >= value, "value not enough");
        balances[msg.sender] -= value;
        token.transfer(msg.sender, value);
        emit Withdraw(msg.sender, value);
    }


}

interface IERC20 {
 
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}