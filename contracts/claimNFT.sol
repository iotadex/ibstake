// SPDX-License-Identifier: UNLICENSED
//

pragma solidity =0.8.17;

import "./ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Reward is Ownable {
    // token address, to set by the owner
    IERC1155 public immutable nftToken;
    uint256[] public tokenids; 

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
        uint256 _rewardAmount,
        address _rewardToken
    ) {
        for (uint256 i = 0; i < _users.length; i++) {
            users[_users[i]] = true;
        }
        rewardAmount = _rewardAmount;
        nftToken = IERC1155(_rewardToken);
        owner = msg.sender;
    }

    function claim() external{
        require(users[msg.sender], "user forbidden");
        require(userClaimed[msg.sender] > 0, "claimed");

        userClaimed[msg.sender] = block.timestamp;
        uint256 tokenid = tokenids[tokenids.length-1];
        tokenids.pop();
        nftToken.safeTransferFrom(address(this), msg.sender, tokenid, 0, "");
    }

    function addTokenIds(uint256[] memory ids) external{
        require(msg.sender == owner, "forbidden");
        for (uint256 i=0;i<ids.length;i++){
            tokenids.push(ids[i]);
        }
    }

    function addUser(address[] memory _users) external{
        require(msg.sender == owner, "forbidden");
        for (uint256 i = 0; i < _users.length; i++) {
            users[_users[i]] = true;
        }
    }
}
