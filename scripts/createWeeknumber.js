// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const weekNumber = 3600;
    let timestamp = Date.parse(new Date()) / 1000;
    timestamp = 1691496000 + weekNumber;
    wn = parseInt(timestamp / weekNumber);
    var wns = new Array();
    var rws = new Array();
    for (var i = 0; i < 156; i++) {
        wns[i] = wn + i;
        rws[i] = Math.round((156 - i) ** 1.5 / 122558.3725 * 8000000) * 100000000;
        //rws[i] = 10000 * 100000000;
    }
    console.log(`[${wns}]`);
    console.log(`[${rws}]`);
    return;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
