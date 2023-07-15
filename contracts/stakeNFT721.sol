// SPDX-License-Identifier: UNLICENSED
//

pragma solidity =0.8.17;

import "./interfaces/IIotabeeSwapNFT.sol";
import "./stakeBase.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeNFT721 is StakeBase, IERC721Receiver {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 public immutable MIN_TICK;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 public immutable MAX_TICK;

    // nft token address for swap of v3
    IIotabeeSwapNFT public immutable nftToken;
    // token0, token1 are the pair of pool, token0 < token1
    address public immutable token0;
    address public immutable token1;
    uint24 public immutable fee;

    struct StakingNFT {
        address owner; // owner of NFT
        uint256 score; // score of the amount
        uint256 beginNo; // as week number, contained
        uint256 endNo; // as week number, not contained
    }
    // all the NFTs, tokenId => stakingNFT
    mapping(uint256 => StakingNFT) public stakingNFTs;
    // user address => tokenIds of NFT
    mapping(address => uint256[]) public userNFTs;

    event Stake(address indexed user, uint256 tokenId, uint256 amount, uint8 k);
    event Withdraw(address indexed user, uint256 tokenId);
    event WithdrawAndMerge(
        address indexed user,
        uint128 liquidity,
        uint256 tokenId,
        uint256 mergeId,
        uint256 token0Fee,
        uint256 token1Fee
    );

    constructor(
        uint8 maxWeeks,
        uint256 maxScale,
        uint8 lockWeeks,
        uint256 beginTime,
        uint256 endTime,
        address _rewardToken,
        address tokenA,
        address tokenB,
        uint24 _fee,
        address nft,
        int24 tickMax
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
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        fee = _fee;
        nftToken = IIotabeeSwapNFT(nft);
        MAX_TICK = tickMax;
        MIN_TICK = -tickMax;

        IERC20(token0).approve(nft, type(uint256).max);
        IERC20(token1).approve(nft, type(uint256).max);
    }

    /// @dev stake NFT for k weeks
    /// @param tokenId the tokenId of NFT
    /// @param k stake the token for k weeks
    function stake(
        uint256 tokenId,
        uint8 k,
        uint256 deadline
    ) external checkDeadline(deadline) {
        require(k > 0 && k <= MAX_WEEKS, "k 1~52");
        require(
            block.timestamp <= END_TIME && block.timestamp >= BEGIN_TIME,
            "not in the period"
        );
        uint256 weekNumber = block.timestamp / WEEK_SECONDS + 1;

        uint256 liquidity = _deposit(tokenId);
        uint256 score = getScore(liquidity, k);

        // add score to totalScore of every week
        for (uint8 i = 0; i < k; i++) {
            totalScores[weekNumber + i] += score;
            userScores[msg.sender][weekNumber + i] += score;
        }

        uint256 endWeek = weekNumber + k; //for gas saving
        stakingNFTs[tokenId] = StakingNFT(
            msg.sender,
            score,
            weekNumber,
            endWeek
        );
        //set user's reward weeks, if begin=end, set current week to the begin
        if (
            userCanClaimWeeks[msg.sender][0] == userCanClaimWeeks[msg.sender][1]
        ) {
            userCanClaimWeeks[msg.sender][0] = weekNumber;
        }
        if (userCanClaimWeeks[msg.sender][1] < endWeek) {
            userCanClaimWeeks[msg.sender][1] = endWeek;
        }
        userNFTs[msg.sender].push(tokenId);
        emit Stake(msg.sender, tokenId, liquidity, k);
    }

    /// @dev withdraw NFT to user
    function withdraw(
        uint256 tokenId,
        uint256 deadline
    ) external checkDeadline(deadline) {
        require(stakingNFTs[tokenId].owner == msg.sender, "owner forbidden");
        uint256 weekNumber = block.timestamp / WEEK_SECONDS;
        require(stakingNFTs[tokenId].endNo <= weekNumber, "locked time");
        uint256[] storage ids = userNFTs[msg.sender];
        for (uint256 i = 0; i < ids.length; i++) {
            if (tokenId == ids[i]) {
                ids[i] = ids[ids.length - 1];
                ids.pop();
                nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
                break;
            }
        }
        emit Withdraw(msg.sender, tokenId);
    }

    /// @dev withdraw NFT to the caller, all the tokenIds must be unstaked
    /// @param tokenId id of NFT to withdraw
    /// @param mergeTokenId id of NFT to merge liquidity
    function withdrawAndMerge(
        uint256 tokenId,
        uint256 mergeTokenId,
        uint256 deadline
    ) external checkDeadline(deadline) {
        //check owner
        require(stakingNFTs[tokenId].owner == msg.sender, "owner forbidden");

        //check stake state
        uint256 weekNumber = block.timestamp / WEEK_SECONDS;
        require(stakingNFTs[tokenId].endNo <= weekNumber, "locked time");

        //check mergeTokenId
        checkNFT(mergeTokenId);
        require(nftToken.ownerOf(mergeTokenId) == msg.sender, "m owner f");

        //remove the tokenId from userNFTs
        uint256[] storage ids = userNFTs[msg.sender];
        for (uint256 i = 0; i < ids.length; i++) {
            if (tokenId == ids[i]) {
                ids[i] = ids[ids.length - 1];
                ids.pop();
                break;
            }
        }

        //decrease liquidity
        (, , , , , , , uint128 liquidity, , , , ) = nftToken.positions(tokenId);
        (uint256 amount0, uint256 amount1) = nftToken.decreaseLiquidity(
            IIotabeeSwapNFT.DecreaseLiquidityParams(
                tokenId,
                liquidity,
                0,
                0,
                deadline
            )
        );
        //collect token0 and token1 to `this` address
        (uint256 amountTotal0, uint256 amountTotal1) = nftToken.collect(
            IIotabeeSwapNFT.CollectParams(
                tokenId,
                address(this),
                type(uint128).max,
                type(uint128).max
            )
        );
        //increase liquidity to the mergeTokenId
        (liquidity, amount0, amount1) = nftToken.increaseLiquidity(
            IIotabeeSwapNFT.IncreaseLiquidityParams(
                mergeTokenId,
                amount0,
                amount1,
                0,
                0,
                deadline
            )
        );
        //burn this tokenId
        nftToken.burn(tokenId);

        //transfer the left token to msg.sender
        _safeTransfer(token0, msg.sender, amountTotal0 - amount0);
        _safeTransfer(token1, msg.sender, amountTotal1 - amount1);

        emit WithdrawAndMerge(
            msg.sender,
            liquidity,
            tokenId,
            mergeTokenId,
            amountTotal0 - amount0,
            amountTotal1 - amount1
        );
    }

    /// @dev get all the user's NFTs that are staking
    /// @return ids the front part are the staking and the back part are expire
    /// @return end is the first index of back part
    function getUserNFTs() external view returns (uint256[] memory, uint256) {
        uint256[] memory ids = new uint256[](userNFTs[msg.sender].length);
        uint256 weekNumber = block.timestamp / WEEK_SECONDS;
        uint256 front = 0;
        uint256 end = userNFTs[msg.sender].length;
        for (uint256 i = 0; i < userNFTs[msg.sender].length; i++) {
            uint256 tokenId = userNFTs[msg.sender][i];
            if (stakingNFTs[tokenId].endNo > weekNumber) {
                ids[front] = tokenId;
                front++;
            } else {
                end--;
                ids[end] = tokenId;
            }
        }
        return (ids, end);
    }

    /// @dev check NFT
    /// @param tokenId nft token id
    function checkNFT(uint256 tokenId) internal view returns (uint256) {
        (
            ,
            ,
            address t0,
            address t1,
            uint24 f,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = nftToken.positions(tokenId);
        require(
            (t0 == token0) && (t1 == token1) && (fee == f),
            "lp pair error"
        );
        require(
            (tickLower == MIN_TICK) && (tickUpper == MAX_TICK),
            "tick range error"
        );
        return liquidity;
    }

    /// @dev deposit user's NFT to this contract
    /// @return liquidity the amount of NFT's liquidity
    function _deposit(uint256 tokenId) internal returns (uint256) {
        uint256 liquidity = checkNFT(tokenId);

        require(nftToken.getApproved(tokenId) == address(this), "not approve");
        nftToken.safeTransferFrom(msg.sender, address(this), tokenId);
        return liquidity;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
