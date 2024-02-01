// SPDX-License-Identifier: UNLICENSED
//

pragma solidity =0.8.17;

import "./ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Reward is Ownable {
    // token address, to set by the owner
    IERC1155 public immutable nftToken;
    uint256 public immutable itemID;

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
        address _rewardToken,
        uint256 _tokenid
    ) {
        for (uint256 i = 0; i < _users.length; i++) {
            users[_users[i]] = true;
        }
        nftToken = IERC1155(_rewardToken);
        itemID = _tokenid;
        owner = msg.sender;
    }

    function claim() external{
        require(users[msg.sender], "user forbidden");
        require(userClaimed[msg.sender] == 0, "claimed");

        userClaimed[msg.sender] = block.timestamp;
        nftToken.safeTransferFrom(address(this), msg.sender, itemID, 1, "");
    }

    function addUser(address[] memory _users) external{
        require(msg.sender == owner, "forbidden");
        for (uint256 i = 0; i < _users.length; i++) {
            users[_users[i]] = true;
        }
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
