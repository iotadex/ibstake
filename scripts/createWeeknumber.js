// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const date = new Date('2023.11.24 03:00:00');
    const beginTime = Date.parse(date) / 1000;
    console.log(`[${beginTime}]`);
    const weekNumber = 18000;
    const endTime = beginTime + 157 * weekNumber;
    console.log(`[${endTime}]`);
    let timestamp = beginTime + weekNumber;
    wn = parseInt(timestamp / weekNumber);
    var wns = new Array();
    var rws = new Array();
    var total = 0n; 
    for (var i = 0; i < 156; i++) {
        wns[i] = wn + i;
        rws[i] = BigInt(Math.round((156 - i) ** 1.5 / 122558.3725 * 120000000)) * 100000000000000n;
        //rws[i] = 200000000n * 10000000000000000n / 156n;
        total += rws[i];
    }
    console.log(`[${wns}]`);
    console.log(`${total}`);
    console.log(`[${rws}]`);
    return;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors. 191000000000000000000
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
// 12000000100000000000000
//       97900000000000000