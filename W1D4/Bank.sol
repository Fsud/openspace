// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    address public admin;
    mapping(address => uint) public balances;
    address[] public top3Address; //top3地址，无顺序

    constructor() {
        admin = msg.sender;
    }

    function withdraw() public virtual{ 
        require(msg.sender == admin,"not admin");
        (payable(admin)).transfer(address(this).balance);
        delete top3Address;
    }

    receive() external payable virtual{ 
        deposit();
    }

    function deposit() public payable virtual{
        if(msg.value > 0){
           balances[msg.sender] += msg.value;
           if(top3Address.length < 3){
            //当top3数组不满时，直接加入数组。当数组中已存在sender时跳过
            for(uint8 i =0;i<top3Address.length;i++){
                if(top3Address[i]==msg.sender){
                    return;
                }
            }
            top3Address.push(msg.sender);
           }else{
            //当top3数组满时，遍历数组，找出金额最小的地址和下标，进行替换。当数组中存在sender时跳过
            uint8 minIndex = type(uint8).max;
            uint min = balances[msg.sender];
            for(uint8 i =0;i<3;i++){
                if(top3Address[i] == msg.sender){
                    return;
                }
                uint amount = balances[top3Address[i]];
                if(min > amount){
                    min = amount;
                    minIndex = i;
                }
            }
            if(min<balances[msg.sender]){
                top3Address[minIndex]=msg.sender;
            }
           }
        }
    }
}