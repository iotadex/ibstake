// SPDX-License-Identifier: UNLICENSED
//

pragma solidity =0.8.17;

import "./ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Reward is Ownable {
    // token address, to set by the owner
    address public immutable rewardToken;

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
        rewardToken = _rewardToken;
        owner = msg.sender;
    }

    function claim() external{
        require(users[msg.sender], "user forbidden");
        require(userClaimed[msg.sender] > 0, "claimed");

        userClaimed[msg.sender] = block.timestamp;
        _safeTransfer(rewardToken, msg.sender, rewardAmount);
    }

    function addUser(address[] memory _users) external{
        require(msg.sender == owner, "forbidden");
        for (uint256 i = 0; i < _users.length; i++) {
            users[_users[i]] = true;
        }
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
}
