// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const nft = await hre.ethers.getContractAt("StakeNFT721", "0x04E7d4A28f61f2E22b71F4842Cdb236092C42466");

    const date = new Date('2023.11.10 20:00:00');
    const beginTime = Date.parse(date) / 1000;
    console.log(`BeginTime is ${beginTime}`);
    const weekSeconds = 604800;
    let timestamp = Date.parse(new Date()) / 1000;
    timestamp = beginTime + weekSeconds;
    wn = parseInt(timestamp / weekSeconds);
    var wns = new Array();
    var rws = new Array();
    for (var i = 0; i < 2; i++) {
        wns[i] = wn + i;
        rws[i] = Math.round((156 - i) ** 1.5 / 122558.3725 * 8000000) * 1000000;
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
