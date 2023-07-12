// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const rewardToken = "0x8CB067473a564F2e72cBcd21d2e2d01CfcB4D222";
    const StakeERC20 = await hre.ethers.getContractAt("StakeERC20", "0xeB64eAdA3E1800FEb8b2e46A0d308F7D39Be5F8A");
    const s = await StakeERC20.rewardsOf(2808069);
    console.log(`totalScores is ${s}`);
    return;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
