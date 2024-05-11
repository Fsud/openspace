// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./EsRNT.sol";
import "./RNT.sol";

contract RNTStake {
    RNT public rnt;
    EsRNT public esRNT;

    uint256 public constant TIRTY_DAYS = 30 * 24 * 60 * 60;
    uint256 public constant mintSpeedPersecond = uint256(1e18) / (24 * 60 * 60); //每一个币每秒产生多少wei的币
    uint256 public constant esTokenSpeedPersecond = uint256(1e18) / (TIRTY_DAYS);

    mapping(address => Stake) public stakes;

    mapping(address => Stake[]) public esStakes;

    modifier before() {
        Stake storage stk = stakes[msg.sender];
        if (stk.amount > 0) {
            stk.debt += stk.amount * mintSpeedPersecond * (block.timestamp - stk.lastUpdate) / 1e18;
            stk.lastUpdate = block.timestamp;
        }
        _;
    }

    constructor(RNT _rnt, EsRNT _esRNT) {
        rnt = _rnt;
        esRNT = _esRNT;
    }

    //approve first
    function stake(uint256 _amount) external before {
        rnt.transferFrom(msg.sender, address(this), _amount);
        Stake storage stk = stakes[msg.sender];
        stk.amount += _amount;
    }

    function claim() external before {
        Stake memory stk = stakes[msg.sender];
        if (stk.debt > 0) {
            esRNT.mint(msg.sender, stk.debt);
        }
        stk.debt = 0;
    }

    function unstake(uint256 _amount) external before {
        Stake memory stk = stakes[msg.sender];
        require(stk.amount >= _amount, "amount not enough");
        stk.amount -= _amount;
        rnt.transfer(msg.sender, _amount);
    }

    //先approve，锁仓之后不能提取，只能burn
    function esTokenLock(uint256 _amount) external {
        require(_amount > 0, "amount should be greater than 0");
        esRNT.transferFrom(msg.sender, address(this), _amount);
        Stake[] storage stks = esStakes[msg.sender];
        stks.push(Stake({amount: _amount, lastUpdate: block.timestamp, debt: 0}));
    }

    //调用此方法，可以将所有锁仓过的esRNT按锁仓时间转换成RNT
    function esTokenBurn() external {
        Stake[] storage stks = esStakes[msg.sender];
        if (stks.length == 0) {
            return;
        }
        uint256 releaseAmount = 0;

        //从数组最后依次累计，并逐个删除
        while (stks.length > 0) {
            Stake memory stk = stks[stks.length - 1];
            uint256 time = block.timestamp - stk.lastUpdate;
            time = time > TIRTY_DAYS ? TIRTY_DAYS : time;
            releaseAmount += stk.amount * esTokenSpeedPersecond * time / 1e18;
            stks.pop();
        }
        rnt.mint(msg.sender, releaseAmount);
    }

    //从index位置burn，并删除index，不维护顺序
    function esTokenBurn(uint256 index) external {
        Stake[] storage stks = esStakes[msg.sender];
        require(index < stks.length, "index out of range");
        Stake memory stk = stks[index];
        uint256 time = block.timestamp - stk.lastUpdate;
        time = time > TIRTY_DAYS ? TIRTY_DAYS : time;
        uint256 releaseAmount = stk.amount * esTokenSpeedPersecond * time / 1e18;

        //删除index元素
        stks[index] = stks[stks.length - 1];
        stks.pop();

        rnt.mint(msg.sender, releaseAmount);
    }
}

struct Stake {
    uint256 debt;
    uint256 lastUpdate;
    uint256 amount;
}
