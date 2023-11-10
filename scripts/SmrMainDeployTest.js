// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const rewardToken = "0x1F8E35099025EE03c89872D80CBb082ce2aBF632";
    const erc20 = await hre.ethers.getContractAt("IERC20", rewardToken)
    const weekSeconds = 3600;
    const fee = 10000;
    const NFT = "0x5f0E8A90f8093aBddF0cA21898B2A71350754a0D";
    const tcikMax = 887200;
    const StakeNFT721 = await hre.ethers.getContractFactory("StakeNFT721");
    const date = new Date('2023.09.30 16:00:00');
    const beginTime = Date.parse(date) / 1000;
    console.log(`BeginTime is ${beginTime}`);
    const endTime = beginTime + 157 * weekSeconds;

    let timestamp = Date.parse(new Date()) / 1000;
    timestamp = beginTime + weekSeconds;
    wn = parseInt(timestamp / weekSeconds);
    var wns = new Array();
    var rws = new Array();
    for (var i = 0; i < 156; i++) {
        wns[i] = wn + i;
        rws[i] = Math.round((156 - i) ** 1.5 / 122558.3725 * 8000000) * 100000000;
    }

    var t0 = "0x1F8E35099025EE03c89872D80CBb082ce2aBF632";
    var t1 = "0x3E3c8701EF91299F235B29535A28B94Ec02236E9";
    let nft = await StakeNFT721.deploy(52, 2, 52, beginTime, endTime, rewardToken, t0, t1, fee, NFT, tcikMax);
    await nft.deployed();
    console.log(`deployed pool(SoonNt1, TT1) StakeNFT721 to ${nft.address}`);

    let b = await erc20.approve(nft.address, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFn)
    console.log(`ERC20 approve ${b}`);

    let now = Date.parse(new Date()) / 1000;
    let total = await nft.setRewards(wns, rws, now + 300);
    console.log(`set rewards to nft ${total}`);

    return

    t0 = "0x0F6Fd00E015080E8D8180D263d1E82270D00F500";
    t1 = "0x1F8E35099025EE03c89872D80CBb082ce2aBF632";
    nft = await StakeNFT721.deploy(52, 2, 52, beginTime, endTime, rewardToken, t0, t1, fee, NFT, tcikMax);
    await nft.deployed();
    console.log(`deployed pool(TT2, SoonNt1) StakeNFT721 to ${nft.address}`);

    b = await erc20.approve(nft.address, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFn)
    console.log(`ERC20 approve ${b}`);

    now = Date.parse(new Date()) / 1000;
    total = await nft.setRewards(wns, rws, now + 300);
    console.log(`set rewards to nft ${total}`);



    t0 = "0x1F8E35099025EE03c89872D80CBb082ce2aBF632";
    t1 = "0xa885FdE6825a07A6413CDAe511Fe446289C863FE";
    nft = await StakeNFT721.deploy(52, 2, 52, beginTime, endTime, rewardToken, t0, t1, fee, NFT, tcikMax);
    await nft.deployed();
    console.log(`deployed pool(SoonNt1, USDT) StakeNFT721 to ${nft.address}`);

    b = await erc20.approve(nft.address, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFn)
    console.log(`ERC20 approve ${b}`);

    now = Date.parse(new Date()) / 1000;
    total = await nft.setRewards(wns, rws, now + 300);
    console.log(`set rewards to nft ${total}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
