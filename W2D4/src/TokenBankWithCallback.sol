// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './TokenBank.sol';

interface TokenRecipient {
    function tokensReceived(address sender, uint256 value, bytes memory data) external returns (bool);
}

contract TokenBankWithCallback is TokenBank, TokenRecipient{

    constructor(address token) TokenBank(token){}

    event TokensReceived(address sender, uint256 value);

    function tokensReceived(address sender, uint256 value, bytes memory ) external returns (bool){
        emit TokensReceived(sender, value);
        //校验，必须从ERC20合约回调过来
        require(msg.sender == address(token), "no auth");
        balances[sender] += value;
        return true;
    }

    function bankBalance(address user) public view returns(uint256){
        return balances[user];
    }



}