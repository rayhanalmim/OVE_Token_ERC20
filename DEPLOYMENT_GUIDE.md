# CMCcoin Token Deployment Guide

This guide will help you deploy the CMCcoin (OVE) token to the BNB Smart Chain.

## Prerequisites

1. **Node.js and npm** installed
2. **Foundry** installed (forge, cast, anvil)
3. **BNB tokens** for gas fees
4. **Private key** of the deployer wallet

## Setup Steps

### 1. Install Dependencies
```bash
# Install Foundry if not already installed
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Build the project
forge build
```

### 2. Configure Environment Variables

Edit the `.env` file with your actual values:

```bash
# For BNB Testnet (recommended for testing first)
RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545/

# For BNB Mainnet (use only when ready for production)
# RPC_URL=https://bsc-dataseed.binance.org/

# Your private key (without 0x prefix)
DEPLOYER=your_private_key_here

# Optional: For contract verification
ETHERSCAN_API_KEY=your_bscscan_api_key_here
```

**⚠️ Security Warning:** Never commit your private keys to version control!

### 3. Get BNB for Gas Fees

#### For Testnet:
- Get free testnet BNB from: https://testnet.binance.org/faucet-smart

#### For Mainnet:
- You'll need real BNB tokens for gas fees

### 4. Deploy the Token

#### Deploy to BNB Testnet (Recommended first):
```bash
forge script script/OVE.s.sol:DeployOVE --rpc-url bsc_testnet --broadcast --verify
```

#### Deploy to BNB Mainnet:
```bash
forge script script/OVE.s.sol:DeployOVE --rpc-url bsc_mainnet --broadcast --verify
```

### 5. Verify Deployment

After deployment, you should see output similar to:
```
CMCcoin deployed to: 0x1234567890123456789012345678901234567890
Total supply: 777700000000000000000000000000
Deployer balance: 777700000000000000000000000000
```

## Token Details

- **Name:** CMCcoin
- **Symbol:** OVE
- **Decimals:** 18
- **Total Supply:** 777,700,000,000 OVE
- **Initial Supply:** All tokens minted to deployer address

## Additional Functions

The deployed contract includes:
- Standard BEP20/ERC20 functions (transfer, approve, etc.)
- Owner-only mint function for additional token creation
- Ownership transfer capabilities

## Useful Commands

### Check token balance:
```bash
cast call <TOKEN_ADDRESS> "balanceOf(address)" <WALLET_ADDRESS> --rpc-url $RPC_URL
```

### Transfer tokens:
```bash
cast send <TOKEN_ADDRESS> "transfer(address,uint256)" <RECIPIENT> <AMOUNT> --private-key $DEPLOYER --rpc-url $RPC_URL
```

### Mint additional tokens (owner only):
```bash
cast send <TOKEN_ADDRESS> "mint(uint256)" <AMOUNT> --private-key $DEPLOYER --rpc-url $RPC_URL
```

## Network Information

### BNB Testnet:
- **Chain ID:** 97
- **RPC URL:** https://data-seed-prebsc-1-s1.binance.org:8545/
- **Explorer:** https://testnet.bscscan.com/

### BNB Mainnet:
- **Chain ID:** 56
- **RPC URL:** https://bsc-dataseed.binance.org/
- **Explorer:** https://bscscan.com/

## Troubleshooting

1. **"Insufficient funds" error:** Make sure you have enough BNB for gas fees
2. **"Invalid private key" error:** Check that your private key is correct and doesn't include the "0x" prefix
3. **RPC connection issues:** Try using different RPC endpoints from the BNB documentation

## Security Best Practices

1. Use testnet first before mainnet deployment
2. Keep private keys secure and never share them
3. Consider using a hardware wallet for mainnet deployments
4. Verify the contract source code on BscScan after deployment