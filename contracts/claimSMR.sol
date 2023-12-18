// SPDX-License-Identifier: UNLICENSED
//

pragma solidity =0.8.17;

import "./ownable.sol";

contract Reward is Ownable {
    // reward amount for one time
    uint256 public immutable rewardAmount;

    // user -> claimed timestamp
    mapping(address => uint256) public userClaimed;

    // users who can claim rewards
    mapping(address => bool) public users;

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "over deadline");
        _;
    }

    constructor(
        address[] memory _users,
        uint256 _rewardAmount
    ) {
        for (uint256 i = 0; i < _users.length; i++) {
            users[_users[i]] = true;
        }
        rewardAmount = _rewardAmount;
        owner = msg.sender;
    }

    function claim() external{
        require(users[msg.sender], "user forbidden");
        require(userClaimed[msg.sender] == 0, "claimed");

        userClaimed[msg.sender] = block.timestamp;
        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        require(success, "!claim");
    }

    function addUser(address[] memory _users) external{
        require(msg.sender == owner, "forbidden");
        for (uint256 i = 0; i < _users.length; i++) {
            users[_users[i]] = true;
        }
    }

    event Received(address Sender, uint Value);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
    
