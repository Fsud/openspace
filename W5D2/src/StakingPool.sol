// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {IToken, IStaking} from "./IToken.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * 编写 StakingPool 合约，实现 Stake 和 Unstake 方法，允许任何人质押ETH来赚钱 KK Token。
 * 其中 KK Token 是每一个区块产出 10 个，产出的 KK Token 需要根据质押时长和质押数量来公平分配。
 * currentRewardsPerToken = accumulatedRewardsPerToken + elapsed * rate  / totalStaked
 * currentUserRewards = accumulatedUserRewards +
 *      userStake * (userRecordedRewardsPerToken - currentRewardsPerToken)
 */
struct StakeInfo {
    uint256 userStake; //总质押的ETH数量
    uint256 accumulatedUserRewards; //用户累计的奖励
    uint256 userRecordedRewardsPerToken; //上次用户记录的每个token的奖励
}

contract StakingPool is IStaking {
    mapping(address => StakeInfo) public stakes;

    uint256 currentRewardsPerToken;

    uint256 startNumber = block.number;

    uint256 rate = 10 * 1e18;

    uint256 totalStaked;

    IToken kkToken;

    using SafeERC20 for IToken;

    uint256 lastUpdateBlock = startNumber;

    event RewardUpdated(uint256 blockNumber, uint256 currentRewardsPerToken);
    event Claim(address indexed account, uint256 amount);
    event Stake(address indexed account, uint256 amount);
    event Unstake(address indexed account, uint256 amount);
    event UserRewardUpdated(
        address indexed account, uint256 accumulatedUserRewards, uint256 userRecordedRewardsPerToken
    );

    constructor(address _kkToken) {
        kkToken = IToken(_kkToken);
    }

    function _updateReward() internal {
        if (totalStaked == 0) return;
        currentRewardsPerToken += (block.number - lastUpdateBlock) * rate / totalStaked;
        lastUpdateBlock = block.number;
        emit RewardUpdated(block.number, currentRewardsPerToken);
    }

    function _updateUserReward(StakeInfo storage stk) internal {
        stk.accumulatedUserRewards += stk.userStake * (currentRewardsPerToken - stk.userRecordedRewardsPerToken);
        stk.userRecordedRewardsPerToken = currentRewardsPerToken;
        emit UserRewardUpdated(msg.sender, stk.accumulatedUserRewards, stk.userRecordedRewardsPerToken);
    }

    /**
     * @dev 质押 ETH 到合约
     */
    function stake() external payable {
        _updateReward();
        StakeInfo storage stk = stakes[msg.sender];
        _updateUserReward(stk);
        stk.userStake += msg.value;
        totalStaked += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    /**
     * @dev 赎回质押的 ETH
     * @param amount 赎回数量
     */
    function unstake(uint256 amount) external {
        StakeInfo storage stk = stakes[msg.sender];
        require(stk.userStake >= amount, "insufficient balance");
        _updateReward();
        _updateUserReward(stk);
        stk.userStake -= amount;
        totalStaked -= amount;
        emit Unstake(msg.sender, amount);
    }

    /**
     * @dev 领取 KK Token 收益
     */
    function claim() external {
        StakeInfo storage stk = stakes[msg.sender];
        _updateReward();
        _updateUserReward(stk);
        uint256 reward = stk.accumulatedUserRewards;
        kkToken.mint(msg.sender, reward);
        stk.accumulatedUserRewards = 0;
        emit Claim(msg.sender, reward);
    }

    /**
     * @dev 获取质押的 ETH 数量
     * @param account 质押账户
     * @return 质押的 ETH 数量
     */
    function balanceOf(address account) external view returns (uint256) {
        return stakes[account].userStake;
    }

    /**
     * @dev 获取待领取的 KK Token 收益
     * @param account 质押账户
     * @return 待领取的 KK Token 收益
     */
    function earned(address account) external view returns (uint256) {
        if (totalStaked == 0) return 0;
        uint256 _currentRewardsPerToken = currentRewardsPerToken + (block.number - lastUpdateBlock) * rate / totalStaked;

        StakeInfo storage stk = stakes[account];
        return stk.accumulatedUserRewards + stk.userStake * (_currentRewardsPerToken - stk.userRecordedRewardsPerToken);
    }
}
