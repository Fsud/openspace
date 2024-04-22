// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Bank.sol';

contract Ownable{

    event Received(address from, address to, uint amount);

    receive() external payable{
        emit Received(msg.sender, address(this), msg.value);
    }

    function withdraw(address payable bank) public{
        BigBank(bank).withdraw();
    }

}


contract BigBank is Bank {


    modifier minValue(uint value){
        require(msg.value >= value,"value too small");
        _;
    }

    function withdraw() public override{
        require(msg.sender == admin,"not admin");
        (payable(admin)).transfer(address(this).balance);
    }

    function deposit() public payable minValue(0.001 ether) override{ 
        super.deposit();
    }

    receive() external minValue(0.001 ether) payable override{
        deposit();
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == admin,"not admin");
        admin = newOwner;
    }

}