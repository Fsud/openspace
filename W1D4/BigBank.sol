// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Bank.sol';
import './Ownable.sol';

contract BigBank is Bank, Ownable {

    //校验最小存入modifier
    modifier minValue(uint value){
        require(msg.value >= value,"value too small");
        _;
    }

    function withdraw() public onlyOwner override{
        (payable(owner)).transfer(address(this).balance);
    }

    function deposit() public payable minValue(0.001 ether) override{ 
        super.deposit();
    }

    receive() external minValue(0.001 ether) payable override{
        deposit();
    }

}