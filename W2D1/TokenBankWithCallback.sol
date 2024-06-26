// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './TokenBank.sol';

contract TokenBankWithCallback is TokenBank{

    constructor(address token) TokenBank(token){}

    event TokensReceived(address sender, uint256 value);

    function tokensReceived(address sender, uint256 value, bytes memory data) public{
        emit TokensReceived(sender, value);
        //校验，必须从ERC20合约回调过来
        require(msg.sender == address(token), "no auth");
        balances[sender] += value;
    }



}