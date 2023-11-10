# Stake Liquidity Contract

The purpose of the contract is to allow people to deposit and stake a certain LP token(ERC20 or NFT721) for a predetermined duration of time and be rewarded with an amount of rewards tokens that’s dependent on the length of time the LP tokens are locked and how many other people have staked.

## Steps for users and owner

1. For a certain pair of dex pool, a stake contract should be deployed. The user can stake their LP token into the contract by calling function `stake`. The stake weeks are between 1 to 52.
2. When user stakes some LP tokens to this contract, they can get reward tokens everyweek. But the reward tokens will lock for 52 weeks. They can call function `claimReward` to claim their reward tokens when unlocked.
3. User's can withdraw their LP tokens when staking time expired.
4. The owner of contract could set rewards for all the weeks by calling function `setRewards`.

## Helper functions
1. `canClaimAmount` get the reward token's amount that user can claim.
2. `lockedRewardAmount` get the reward token's amount that are locked in the contract.
3. `getUserNFTs` get user's NFT tokens all in the contract.
4. 
```shell
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

    uint24 public constant WEEK_SECONDS = 600;
    uint8 public immutable MAX_WEEKS;
    uint256 public immutable MAX_SCALE;
    uint8 public immutable LOCK_WEEKNUM;
    uint256 public immutable BEGIN_TIME;
    uint256 public immutable END_TIME;

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
```


# Development
Use following tasks to manage:
```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```

这个操作又三个步骤：
把nft token 从stake合约发送给用户，需要鉴权调用者是否是合法用户
提现的nft token中的liquidity全部移除，需要鉴权nft token的拥有者身份，移除的同时执行collect操作，获得ERC20代币
把移除liquidity的量再通过addLiquidity的方式加到已有的nft token中。

l^2 = s * s * p
