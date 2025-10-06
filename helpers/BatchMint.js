require("dotenv").config({ path: ".env" });
const ethers = require("ethers");

/* Import the environment variables. */
const { RPC_URL, DEPLOYER } = process.env;

const provider = new ethers.providers.JsonRpcProvider(RPC_URL);

let wallet = new ethers.Wallet(DEPLOYER, provider);

const ABI = require("./ABI_Marketplace.json");
const iface = new ethers.utils.Interface(ABI);
const gasPrice = ethers.utils.parseUnits("10", "gwei");

async function main() {
  const ctx = new ethers.Contract(
    "0xa1d19005917C7aC862a6A9a9900c3A493B790bee",
    iface,
    wallet
  );
  const tokenUris = [];

  for (let i = 0; i < 60; i++) {
    tokenUris.push(
      `ipfs://QmVcNNAmbbcSVvxacQGZoMacKQQDtSDMBcKynUy73f1Mpk/cItems/cItem${i}.json`
    );
  }
  const tx = await ctx.batchMint(
    "0x8AF10C657337358111C0ABC2991b53EbF0B52C79",
    tokenUris,
    {
      gasPrice,
      gasLimit: "0x1C9C380",
    }
  );
  console.log(tx.hash);
}

main();
