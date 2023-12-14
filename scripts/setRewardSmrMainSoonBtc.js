// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const nft = await hre.ethers.getContractAt("StakeNFT721", "0x987d83af72AFe343e1A7bafaF968c8340bEe3EfA");

    const date = new Date('2023.10.01 20:00:00');
    const beginTime = Date.parse(date) / 1000;
    console.log(`BeginTime is ${beginTime}`);
    const weekSeconds = 604800;
    let timestamp = Date.parse(new Date()) / 1000;
    timestamp = beginTime + weekSeconds;
    wn = parseInt(timestamp / weekSeconds);
    var wns = new Array();
    var rws = new Array();
    for (var i = 8; i < 12; i++) {
        wns[i] = wn + i;
        rws[i] = Math.round((156 - i) ** 1.5 / 122558.3725 * 8000000 * 1000000);
    }
    console.log(`${wns}`);
    console.log(`${rws}`);
    return;

    let now = Date.parse(new Date()) / 1000;
    let total = await nft.setRewards(wns, rws, now + 300);
    console.log(`set rewards to nft ${total}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
