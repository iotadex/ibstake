// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const rewardToken = "0x39DEE4dFA8A94fB02F4004a38543c853F859d79E";
  const weekSeconds = 3600;
  const t0 = "0x68018Bf6127aD04Ad9b6b0f8ACf18fD5651dE0C8";
  const t1 = "0xf0D82b7837fC074B8d349e3cEd773089fA77Fde3";
  const fee = 10000;
  const NFT = "0xA003566666347dB17fd0aD4e47205901A370A51d";
  const tcikMax = 887200;
  const StakeNFT721 = await hre.ethers.getContractFactory("StakeNFT721");
  const date = new Date('2023.09.06 15:00:00');
  const beginTime = Date.parse(date) / 1000;
  console.log(`BeginTime is ${beginTime}`);
  const endTime = beginTime + 157 * weekSeconds;
  const nft = await StakeNFT721.deploy(52, 2, 52, beginTime, endTime, rewardToken, t0, t1, fee, NFT, tcikMax);
  await nft.deployed();
  console.log(`deployed pool(0x7326c0F9d0B64E23eec22d39d571e71a69a011CE) StakeNFT721 to ${nft.address}`);

  const erc20 = await hre.ethers.getContractAt("IERC20", rewardToken)
  const b = await erc20.approve(nft.address, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFn)
  console.log(`ERC20 approve ${b}`);

  let timestamp = Date.parse(new Date()) / 1000;
  timestamp = beginTime + weekSeconds;
  wn = parseInt(timestamp / weekSeconds);
  var wns = new Array();
  var rws = new Array();
  for (var i = 0; i < 156; i++) {
    wns[i] = wn + i;
    rws[i] = Math.round((156 - i) ** 1.5 / 122558.3725 * 8000000) * 100000000;
    //rws[i] = 10000 * 100000000;
  }

  let now = Date.parse(new Date()) / 1000;
  const total = await nft.setRewards(wns, rws, now + 300);
  console.log(`set rewards to nft ${total}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
