// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const rewardToken = "0x3C844FB5AD27A078d945dDDA8076A4084A76E513";
    const erc20 = await hre.ethers.getContractAt("IERC20", rewardToken)
    const weekSeconds = 604800;
    const fee = 10000;
    const NFT = "0x5f0E8A90f8093aBddF0cA21898B2A71350754a0D";
    const tcikMax = 887200;
    const StakeNFT721 = await hre.ethers.getContractFactory("StakeNFT721");
    const date = new Date('2023.10.01 20:00:00');
    const beginTime = Date.parse(date) / 1000;
    console.log(`BeginTime is ${beginTime}`);
    const endTime = beginTime + 157 * weekSeconds;

    var t0 = "0x1cDF3F46DbF8Cf099D218cF96A769cea82F75316";
    var t1 = "0x3C844FB5AD27A078d945dDDA8076A4084A76E513";
    let nft = await StakeNFT721.deploy(52, 2, 52, beginTime, endTime, rewardToken, t0, t1, fee, NFT, tcikMax);
    await nft.deployed();
    console.log(`deployed pool(sBTC, sSOON) StakeNFT721 to ${nft.address}`);

    let b = await erc20.approve(nft.address, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFn)
    console.log(`ERC20 approve ${b}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
