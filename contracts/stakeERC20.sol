// SPDX-License-Identifier: UNLICENSED
//

pragma solidity =0.8.17;

import "./stakeBase.sol";

contract StakeERC20 is StakeBase {
    // erc20 token address for swap of v2
    address public immutable lpToken;

    struct StakingERC20 {
        uint256 amount; // lp token amount
        uint256 score; // score of the amount
        uint256 beginNo; // as week number, contained
        uint256 endNo; // as week number, not contained
    }
    // the current index id to stake
    uint256 public nonce;
    // id => stakingERC20, it will be delete when it's withdrew
    mapping(uint256 => StakingERC20) public stakingERC20s;
    // user address => ids of stakingERC20s
    mapping(address => uint256[]) public userERC20s;

    event Stake(address indexed user, uint256 id, uint256 amount, uint8 k);
    event Withdraw(address indexed user, uint256 amount);

    constructor(
        uint8 maxWeeks,
        uint256 maxScale,
        uint8 lockWeeks,
        uint256 beginTime,
        uint256 endTime,
        address _rewardToken,
        address _lpToken
    )
        StakeBase(
            maxWeeks,
            maxScale,
            lockWeeks,
            beginTime,
            endTime,
            _rewardToken
        )
    {
        lpToken = _lpToken;
    }

    /// @dev stake erc20 token of `amount` for k weeks
    /// @param amount transfer erc20 token to this contract
    /// @param k stake the token for k weeks
    function stake(uint256 amount, uint8 k) external {
        require(k > 0 && k <= MAX_WEEKS, "k 1~52");
        require(
            block.timestamp <= END_TIME && block.timestamp >= BEGIN_TIME,
            "not in the period"
        );
        uint256 weekNumber = block.timestamp / WEEK_SECONDS + 1;

        _safeTransferFrom(lpToken, msg.sender, address(this), amount);
        uint256 score = getScore(amount, k);

        // add score to totalScore of every week
        for (uint8 i = 0; i < k; i++) {
            totalScores[weekNumber + i] += score;
            userScores[msg.sender][weekNumber + i] += score;
        }

        uint256 endWeek = weekNumber + k; //for gas saving
        stakingERC20s[nonce] = StakingERC20(amount, score, weekNumber, endWeek);
        //set user's reward weeks, if begin=end, set current week to the begin
        if (
            userCanClaimWeeks[msg.sender][0] == userCanClaimWeeks[msg.sender][1]
        ) {
            userCanClaimWeeks[msg.sender][0] = weekNumber;
        }
        if (userCanClaimWeeks[msg.sender][1] < endWeek) {
            userCanClaimWeeks[msg.sender][1] = endWeek;
        }
        userERC20s[msg.sender].push(nonce);
        emit Stake(msg.sender, nonce, amount, k);
        nonce++;
    }

    /// @dev withdraw token to the caller
    /// @return total the real amount of erc20 token transfered
    function withdraw() external returns (uint256 total) {
        uint256 weekNumber = block.timestamp / WEEK_SECONDS;
        uint256 i = userERC20s[msg.sender].length;
        while (userERC20s[msg.sender].length > 0) {
            i--;
            uint256 id = userERC20s[msg.sender][i];
            if (stakingERC20s[id].endNo <= weekNumber) {
                // when the staking erc20 token expire
                total += stakingERC20s[id].amount;
                userERC20s[msg.sender][i] = userERC20s[msg.sender][
                    userERC20s[msg.sender].length - 1
                ];
                userERC20s[msg.sender].pop();
            }
            if (i == 0) {
                break;
            }
        }
        if (total > 0) {
            _safeTransfer(lpToken, msg.sender, total);
        }
        emit Withdraw(msg.sender, total);
    }

    function getStaking() external view returns (StakingERC20[] memory) {
        uint256 size = userERC20s[msg.sender].length;
        StakingERC20[] memory s = new StakingERC20[](size);
        for (uint256 i = 0; i < size; i++) {
            s[i] = stakingERC20s[userERC20s[msg.sender][i]];
        }
        return s;
    }
}
