// SPDX-License-Identifier: UNLICENSED
//

pragma solidity =0.8.17;

import "./ownable.sol";

contract StakeBase is Ownable {
    // token address, to set by the owner
    address public immutable rewardToken;
    // user address => week number => score
    mapping(address => mapping(uint256 => uint256)) public userScores;
    //user address => [begin week number, end week number]
    mapping(address => uint256[2]) public userCanClaimWeeks;

    // weekNumber => score
    mapping(uint256 => uint256) public totalScores;
    // the owner to set, week number => reward token amount
    mapping(uint256 => uint256) public rewardsOf;
    // the lastest week number
    uint256 public latestNo;

    uint24 public constant WEEK_SECONDS = 604800; // seconds of one week
    uint8 public immutable MAX_WEEKS;
    uint256 public immutable MAX_SCALE;
    uint8 public immutable LOCK_WEEKNUM;
    uint256 public immutable BEGIN_TIME;
    uint256 public immutable END_TIME;

    event SetReward(address indexed user, uint256 no, uint256 amount);
    event ClaimReward(address indexed user, uint256 amount);

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "over deadline");
        _;
    }

    constructor(
        uint8 maxWeeks,
        uint256 maxScale,
        uint8 lockWeeks,
        uint256 beginTime,
        uint256 endTime,
        address _rewardToken
    ) {
        rewardToken = _rewardToken;
        MAX_WEEKS = maxWeeks;
        MAX_SCALE = maxScale;
        LOCK_WEEKNUM = lockWeeks;
        BEGIN_TIME = beginTime;
        END_TIME = endTime;

        owner = msg.sender;
    }

    /// @dev set rewardToken to this contract, with transfering token
    /// @param no the week number
    /// @param amount the reward amount for rewardToken
    function setReward(
        uint256 no,
        uint256 amount,
        uint256 deadline
    ) external checkDeadline(deadline) {
        require(msg.sender == owner, "forbidden");
        _safeTransferFrom(rewardToken, msg.sender, address(this), amount);
        rewardsOf[no] += amount;
        if (no > latestNo) {
            latestNo = no;
        }
        emit SetReward(msg.sender, no, amount);
    }

    /// @dev set rewardToken to this contract, with transfering token
    /// @param nos the week numbers
    /// @param amounts the reward amounts for rewardToken
    function setRewards(
        uint256[] memory nos,
        uint256[] memory amounts,
        uint256 deadline
    ) external checkDeadline(deadline) {
        require(msg.sender == owner, "forbidden");
        require(nos.length == amounts.length, "parameters error");
        uint256 lno = 0; // gas saved
        for (uint256 i = 0; i < nos.length; i++) {
            rewardsOf[nos[i]] = amounts[i];
            if (nos[i] > lno) {
                lno = nos[i];
            }
        }
        latestNo = lno;
    }

    function userRewards() internal view returns (uint256, uint256[] memory) {
        uint256 weekNumber = block.timestamp / WEEK_SECONDS;
        (uint256 w1, uint256 w2) = (
            userCanClaimWeeks[msg.sender][0],
            userCanClaimWeeks[msg.sender][1]
        );
        uint256 bE = w2 < weekNumber ? w2 : weekNumber;
        uint256[] memory amountList = new uint256[](w2 - bE);
        for (uint256 no = w1; no < bE; no++) {
            amountList[no - w1] = totalScores[no] == 0
                ? 0
                : (rewardsOf[no] * userScores[msg.sender][no]) /
                    totalScores[no];
        }
        return (w1, amountList);
    }

    /// @dev claim all the rewards for user's staking
    function claimReward(uint256 deadline) external checkDeadline(deadline) {
        uint256 weekNumber = block.timestamp / WEEK_SECONDS - LOCK_WEEKNUM;
        uint256 total = 0;
        uint256 updataNo = userCanClaimWeeks[msg.sender][0];
        for (
            uint256 no = updataNo;
            no < userCanClaimWeeks[msg.sender][1];
            no++
        ) {
            if (no > weekNumber) {
                break;
            }
            updataNo = no + 1;
            if (totalScores[no] == 0) {
                continue;
            }
            total +=
                (rewardsOf[no] * userScores[msg.sender][no]) /
                totalScores[no];
        }
        userCanClaimWeeks[msg.sender][0] = updataNo;
        _safeTransfer(rewardToken, msg.sender, total);
        emit ClaimReward(msg.sender, total);
    }

    function canClaimAmount(address user) public view returns (uint256) {
        uint256 weekNumber = block.timestamp / WEEK_SECONDS - LOCK_WEEKNUM;
        uint256 total = 0;
        for (
            uint256 no = userCanClaimWeeks[user][0];
            no < userCanClaimWeeks[user][1];
            no++
        ) {
            // cann't be over the locked week number
            if (no > weekNumber) {
                break;
            }
            if (totalScores[no] == 0) {
                continue;
            }
            total += (rewardsOf[no] * userScores[user][no]) / totalScores[no];
        }
        return total;
    }

    function lockedRewardAmount(
        address user
    ) public view returns (uint256, uint256[] memory) {
        uint256 weekNumber = block.timestamp / WEEK_SECONDS - LOCK_WEEKNUM + 1;
        if (userCanClaimWeeks[user][1] <= weekNumber) {
            return (weekNumber, new uint256[](0));
        }
        (uint256 w1, uint256 w2) = (
            userCanClaimWeeks[user][0],
            userCanClaimWeeks[user][1]
        );
        uint256 bI = w1 > weekNumber ? w1 : weekNumber;
        uint256[] memory amountList = new uint256[](w2 - bI);
        for (uint256 no = bI; no < w2; no++) {
            amountList[no - bI] = totalScores[no] == 0
                ? 0
                : (rewardsOf[no] * userScores[user][no]) / totalScores[no];
        }
        uint256 first = LOCK_WEEKNUM + bI - block.timestamp / WEEK_SECONDS;
        return (first, amountList);
    }

    /// @dev get the score for amount and k by using a liner equation
    /// @param amount the amount of token to stake
    /// @param k is the x of equation
    /// @return score is the y of equation
    function getScore(
        uint256 amount,
        uint8 k
    ) public view returns (uint256 score) {
        score =
            (amount * ((MAX_SCALE - 1) * (k - 1) + MAX_WEEKS - 1)) /
            (MAX_WEEKS - 1);
    }

    /// @dev safe tranfer erc20 token frome address(this) to address
    function _safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    /// @dev safe tranfer erc20 token from address to address
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "transferFrom failed"
        );
    }
}
