const { ethers } = require('ethers');
require('dotenv').config();

// Contract ABI (minimal for deployment)
const contractABI = [
    "constructor()",
    "function name() view returns (string)",
    "function symbol() view returns (string)",
    "function totalSupply() view returns (uint256)",
    "function balanceOf(address) view returns (uint256)"
];

// Contract bytecode - you'll need to compile this first
const contractBytecode = "0x608060405234801561001057600080fd5b50..."; // This needs to be the compiled bytecode

async function deployToken() {
    try {
        // Setup provider and wallet
        const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
        const wallet = new ethers.Wallet(process.env.DEPLOYER, provider);
        
        console.log("Deploying from address:", wallet.address);
        console.log("Network:", await provider.getNetwork());
        
        // Check balance
        const balance = await provider.getBalance(wallet.address);
        console.log("Balance:", ethers.formatEther(balance), "BNB");
        
        if (balance === 0n) {
            throw new Error("Insufficient balance for deployment");
        }
        
        // Create contract factory
        const contractFactory = new ethers.ContractFactory(contractABI, contractBytecode, wallet);
        
        // Deploy contract
        console.log("Deploying CMCcoin token...");
        const contract = await contractFactory.deploy();
        
        console.log("Transaction hash:", contract.deploymentTransaction().hash);
        console.log("Waiting for confirmation...");
        
        // Wait for deployment
        await contract.waitForDeployment();
        
        const contractAddress = await contract.getAddress();
        console.log("✅ CMCcoin deployed successfully!");
        console.log("Contract address:", contractAddress);
        
        // Get token info
        const name = await contract.name();
        const symbol = await contract.symbol();
        const totalSupply = await contract.totalSupply();
        const deployerBalance = await contract.balanceOf(wallet.address);
        
        console.log("\n📊 Token Information:");
        console.log("Name:", name);
        console.log("Symbol:", symbol);
        console.log("Total Supply:", ethers.formatEther(totalSupply));
        console.log("Deployer Balance:", ethers.formatEther(deployerBalance));
        console.log("\n🔗 BSC Testnet Explorer:");
        console.log(`https://testnet.bscscan.com/address/${contractAddress}`);
        
    } catch (error) {
        console.error("❌ Deployment failed:", error.message);
    }
}

deployToken();