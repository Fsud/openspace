// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 *
 * IDO合约
 * 软顶不到则退款
 * 超过硬顶则所有用户按比例分配token，并退还多余的eth
 */
contract RNTIDO {
    IERC20 public immutable token;
    address public immutable owner;
    uint256 public price; // 每一个token值多少wei, 此token默认无精度
    uint256 public softCap; // 单位wei
    uint256 public hardCap; // 单位wei
    uint256 public endTime;

    uint256 public endBalance; // 总募得以太币数额
    uint256 public tokenSaleAmount; //IDO 代币数量

    mapping(address => uint256) public balances;

    using Address for address payable;

    event InitIDO(uint256 tokenSaleAmount, uint256 price, uint256 softCap, uint256 hardCap, uint256 endTime);
    event Buy(address indexed user, uint256 amount);
    event WithdrawToken(address indexed user, uint256 ethValue, uint256 tokenValue);
    event WithdrawOwner(uint256 ethValue, uint256 tokenValue);
    event Refund(address indexed user, uint256 amount);
    event RefundOwner(uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
        owner = msg.sender;
    }

    /**
     * @dev owner调用initIDO前，需要先向IDO合约转入足够的token
     */
    function initIDO(uint256 _price, uint256 _softCap, uint256 _hardCap, uint256 _endTime) external {
        require(msg.sender == owner, "Only owner can initialize IDO");
        tokenSaleAmount = token.balanceOf(address(this));
        require(tokenSaleAmount == _hardCap / _price, "Please transfer enough tokens in IDO contract");
        require(_endTime > block.timestamp, "End time should be in the future");
        require(_softCap < _hardCap, "Soft cap should be less than hard cap");

        price = _price;
        softCap = _softCap;
        hardCap = _hardCap;
        endTime = _endTime;
        emit InitIDO(tokenSaleAmount, price, softCap, hardCap, endTime);
    }

    function buy() external payable {
        require(block.timestamp < endTime, "IDO has ended");
        require(msg.value > 0, "You need to send some ether");
        uint256 balance = balances[msg.sender];
        if (balance == 0) {
            balances[msg.sender] = msg.value;
        } else {
            balances[msg.sender] = balance + msg.value;
        }
        endBalance += msg.value;
        emit Buy(msg.sender, msg.value);
    }

    // 未到达软顶，用户可以退款
    function refund() public {
        require(block.timestamp > endTime, "IDO has not ended yet");
        require(endBalance < softCap, "Soft cap reached");
        uint256 investAmount = balances[msg.sender];
        require(investAmount > 0, "Not join ido");
        balances[msg.sender] = 0;
        payable(msg.sender).sendValue(investAmount);
        emit Refund(msg.sender, investAmount);
    }

    //到达硬顶，用户可以提取token
    function withdrawToken() public {
        require(block.timestamp > endTime, "IDO has not ended yet");
        require(endBalance >= softCap, "Soft not reached");
        uint256 investBalance = balances[msg.sender];
        require(investBalance > 0, "Not join ido");

        if (endBalance <= hardCap) {
            //未超过硬顶，不用退eth
            token.transfer(msg.sender, investBalance / price);
            balances[msg.sender] = 0;
            emit WithdrawToken(msg.sender, 0, investBalance / price);
        } else {
            //超过硬顶，需退eth
            uint256 tokenAmount = tokenSaleAmount * investBalance / endBalance;
            token.transfer(msg.sender, tokenAmount);
            balances[msg.sender] = 0;
            uint256 ethValue = investBalance - tokenAmount * price;
            payable(msg.sender).sendValue(ethValue);
            emit WithdrawToken(msg.sender, ethValue, tokenAmount);
        }
    }

    // 到达软顶，owner可以提取eth
    function withdrawOwner() public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(block.timestamp > endTime, "IDO has not ended yet");
        require(endBalance >= softCap, "Soft not reached");
        if (endBalance >= hardCap) {
            //超过硬顶，owner提取eth
            uint256 min = address(this).balance < hardCap ? address(this).balance : hardCap;
            payable(owner).sendValue(min);
            emit WithdrawOwner(min, 0);
        } else {
            uint256 ownerWithdrawAmount = tokenSaleAmount - endBalance / price;
            payable(owner).sendValue(endBalance);
            token.transfer(owner, ownerWithdrawAmount);
            emit WithdrawOwner(endBalance, ownerWithdrawAmount);
        }
    }

    // 未到达软顶，owner可以提取token
    function refundOwner() public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(block.timestamp > endTime, "IDO has not ended yet");
        require(endBalance < softCap, "Soft reached");
        token.transfer(msg.sender, tokenSaleAmount);
        emit RefundOwner(tokenSaleAmount);
    }
}
