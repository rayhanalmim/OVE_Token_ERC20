require("dotenv").config({ path: ".env" });
const ethers = require("ethers");

/* Import the environment variables. */
const { RPC_URL, ACCOUNT2 } = process.env;

const provider = new ethers.providers.JsonRpcProvider(RPC_URL);

let wallet = new ethers.Wallet(ACCOUNT2, provider);

const ABI = require("./ABI/ERC721.json");
const iface = new ethers.utils.Interface(ABI);
const gasPrice = ethers.utils.parseUnits("10", "gwei");

async function main() {
  const ctx = new ethers.Contract(
    "0xf647f1f7e21dbee538e676930dd5ae3133a82db5",
    iface,
    wallet
  );

  const tx = await ctx.buy.staticCall(
    8,
    "0x1a2093ac3ff9798ae4609f5fa2ead3152f33b99a",
    1,
    "0xddd249b862a6c4acee4d343fc15818755178f893",
    10 ** 18
  );
  console.log(tx);
}

main();
