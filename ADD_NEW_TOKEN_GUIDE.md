# 📘 Complete Guide: Adding a New Token Pair for OVE Swap

## 🎯 Overview

This guide walks you through the **complete journey** of adding a new token (e.g., USDT, BUSD, ETH, etc.) to swap with OVE tokens.

---

## 📋 Prerequisites

Before adding a new token, gather this information:

| Information | Example | How to Get |
|-------------|---------|------------|
| **Token Address** | `0x55d398326f99059fF775485246999027B3197955` | Token contract address on BSC |
| **Token Decimals** | `18` or `6` | Check token contract |
| **Token Symbol** | `USDT`, `BUSD`, etc. | From token contract |
| **Current Market Price** | `$1.00` for stablecoins | CoinGecko, CMC |
| **Chainlink Price Feed** (optional) | `0xB97Ad0E74fa7d920791E90258A6E2085088b4320` | [Chainlink Feeds](https://docs.chain.link/data-feeds/price-feeds/addresses) |

---

## 🛣️ Complete Journey: 2 Methods

### **Method 1: With Chainlink Price Feed (Recommended)**
✅ **Best for:** Major tokens (USDT, BUSD, BTC, ETH, BNB)  
✅ **Benefits:** Automatic price updates, real-time market rates  
✅ **Requirements:** Chainlink price feed must exist for the token

### **Method 2: Manual Fixed Rate**
⚠️ **Best for:** Smaller tokens without Chainlink feeds  
⚠️ **Downside:** Requires manual rate updates  
✅ **Benefits:** Works for any token

---

## 🚀 Method 1: Adding Token WITH Chainlink Price Feed

### **Step 1: Find Chainlink Price Feed Address**

Visit [Chainlink Price Feeds](https://docs.chain.link/data-feeds/price-feeds/addresses?network=bnb-chain)

**BSC Mainnet Examples:**
```solidity
USDT/USD: 0xB97Ad0E74fa7d920791E90258A6E2085088b4320
BUSD/USD: 0xcBb98864Ef56E9042e7d2efef76141f15731B82f
ETH/USD:  0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e
BTC/USD:  0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf
```

**BSC Testnet Examples:**
```solidity
BNB/USD:  0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
BTC/USD:  0x5741306c21795FdCBb9b265Ea0255F499DFe515C
BUSD/USD: 0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa
```

---

### **Step 2: Add Token with Price Feed (Admin Call)**

Call these 2 functions from contract owner address:

#### **2a. Add Token Support**
```solidity
// Function signature
addSupportedToken(
    address token,     // New token address
    uint256 rate,      // Fallback rate (18 decimals) - not used if Chainlink active
    bool active        // Set to true to enable immediately
)

// Example: Adding USDT
addSupportedToken(
    0x55d398326f99059fF775485246999027B3197955,  // USDT address
    100000000000000000,  // 0.1 (placeholder - Chainlink will override)
    true                 // Active immediately
)
```

#### **2b. Set Chainlink Price Feed**
```solidity
// Function signature
setPriceFeed(
    address token,      // Token address
    address priceFeed   // Chainlink feed address
)

// Example: Setting USDT price feed
setPriceFeed(
    0x55d398326f99059fF775485246999027B3197955,  // USDT address
    0xB97Ad0E74fa7d920791E90258A6E2085088b4320   // USDT/USD feed
)
```

---

### **Step 3: Set OVE Price (If Not Already Set)**

```solidity
// Function signature
setOVEPriceInUSD(uint256 _priceInUSD)

// Example: Set OVE = $0.01 (1 cent)
setOVEPriceInUSD(1000000)  // 0.01 USD with 8 decimals

// Example: Set OVE = $0.05 (5 cents)
setOVEPriceInUSD(5000000)  // 0.05 USD with 8 decimals

// Example: Set OVE = $1.00
setOVEPriceInUSD(100000000)  // 1.00 USD with 8 decimals
```

**Important:** Price format = `USD_PRICE * 10^8`
- $0.01 = `1000000` (1 * 10^6)
- $0.10 = `10000000` (1 * 10^7)
- $1.00 = `100000000` (1 * 10^8)

---

### **Step 4: Add Liquidity**

Before users can swap, you need to provide liquidity:

```solidity
// First, approve the swap contract to spend your tokens
// On the TOKEN contract, call:
approve(swapContractAddress, amount)

// Then add liquidity on swap contract:
addLiquidity(tokenAddress, amount)
```

**Example: Adding 10,000 USDT liquidity**
```javascript
// Step 1: On USDT contract
USDT.approve(swapContract, 10000000000) // 10,000 USDT (6 decimals)

// Step 2: On Swap contract
swap.addLiquidity(
    "0x55d398326f99059fF775485246999027B3197955",  // USDT
    10000000000  // 10,000 USDT (adjust for decimals)
)
```

**Also add OVE liquidity:**
```javascript
// On OVE token contract
OVE.approve(swapContract, amount)

// On Swap contract
swap.addOVELiquidity(1000000000000000000000000)  // 1 million OVE
```

---

### **Step 5: Verify & Test**

#### **5a. Check Token Support**
```solidity
// View function - no gas required
supportedTokens(tokenAddress)  // Should return true
isActive(tokenAddress)         // Should return true
hasCustomPriceFeed(tokenAddress)  // Should return true
```

#### **5b. Check Current Price**
```solidity
// Get price info
getPriceInfo(tokenAddress)
// Returns:
// - ovePriceUSD: Current OVE price (e.g., 1000000 = $0.01)
// - tokenPriceUSD: Current token price (e.g., 100000000 = $1.00)
// - exchangeRate: Calculated rate (18 decimals)
// - isAutomatic: true (using Chainlink)
```

#### **5c. Test Swap Quote**
```solidity
// Calculate how much OVE you get for 100 USDT
calculateBuyOVEWithFees(
    usdtAddress,
    100000000  // 100 USDT (assuming 6 decimals)
)
// Returns: (oveAmount, feeAmount)
```

#### **5d. Check Liquidity**
```solidity
// Check contract balances
getContractBalance(tokenAddress)  // Token liquidity
getContractBalance(oveTokenAddress)  // OVE liquidity
```

---

## 🔧 Method 2: Adding Token WITHOUT Chainlink (Manual Rate)

### **Step 1: Calculate Manual Exchange Rate**

Formula: `rate = (TOKEN_PRICE_USD / OVE_PRICE_USD) * 10^18`

**Example Calculation:**
```
Given:
- USDT price = $1.00
- OVE price = $0.01

Calculation:
rate = (1.00 / 0.01) * 10^18
rate = 100 * 10^18
rate = 100000000000000000000

Meaning: 1 OVE = 100 USDT tokens
```

**More Examples:**

| Token | Token Price | OVE Price | Calculation | Rate (18 decimals) |
|-------|-------------|-----------|-------------|-------------------|
| USDT | $1.00 | $0.01 | (1/0.01) * 10^18 | 100000000000000000000 |
| Custom | $0.50 | $0.01 | (0.5/0.01) * 10^18 | 50000000000000000000 |
| Custom | $10.00 | $0.01 | (10/0.01) * 10^18 | 1000000000000000000000 |

---

### **Step 2: Add Token with Manual Rate**

```solidity
// Add token with calculated rate
addSupportedToken(
    tokenAddress,
    calculatedRate,  // From step 1
    true            // Active
)

// Example: Adding custom token at $0.50
addSupportedToken(
    0xCustomToken...,
    50000000000000000000,  // Rate from calculation
    true
)
```

---

### **Step 3: Disable Automatic Pricing (Optional)**

If you want to ensure manual rate is used:

```solidity
// Option A: Disable automatic pricing globally
setAutomaticPricing(false)

// Option B: Disable for specific token only
setManualRateOverride(tokenAddress, true)
```

---

### **Step 4: Add Liquidity & Test**

Same as Method 1 Steps 4-5.

---

### **Step 5: Update Rate When Needed**

Since manual rates don't auto-update, you'll need to update them:

```solidity
// Update exchange rate when prices change
updateExchangeRate(tokenAddress, newRate)

// Example: Updating when token price changes
updateExchangeRate(
    0xCustomToken...,
    60000000000000000000  // New rate
)
```

---

## 🎮 Using Quick Setup Functions

For common tokens, use convenience functions:

### **On Testnet:**
```solidity
addTestnetTokens(
    wbnbAddress,   // Wrapped BNB address
    btcAddress,    // Wrapped BTC address
    busdAddress    // BUSD address
)
```

### **On Mainnet:**
```solidity
addMainnetTokens(
    wbnbAddress,   // Wrapped BNB address
    ethAddress,    // Wrapped ETH address
    btcAddress,    // Wrapped BTC address
    usdtAddress    // USDT address
)
```

These functions automatically:
- Add token support
- Set Chainlink price feeds
- Enable trading

---

## 📊 Complete Example: Adding USDT on BSC Mainnet

```javascript
// Contract addresses
const SWAP_CONTRACT = "0xYourSwapContract..."
const USDT_ADDRESS = "0x55d398326f99059fF775485246999027B3197955"
const USDT_USD_FEED = "0xB97Ad0E74fa7d920791E90258A6E2085088b4320"
const OVE_ADDRESS = "0xYourOVEToken..."

// Step 1: Add token support
await swap.addSupportedToken(
    USDT_ADDRESS,
    100000000000000000000,  // Placeholder rate
    true                     // Active
)

// Step 2: Set Chainlink price feed
await swap.setPriceFeed(
    USDT_ADDRESS,
    USDT_USD_FEED
)

// Step 3: Set OVE price (if not set)
await swap.setOVEPriceInUSD(1000000)  // $0.01

// Step 4: Add USDT liquidity
await USDT.approve(SWAP_CONTRACT, ethers.parseUnits("10000", 6))
await swap.addLiquidity(USDT_ADDRESS, ethers.parseUnits("10000", 6))

// Step 5: Add OVE liquidity
await OVE.approve(SWAP_CONTRACT, ethers.parseUnits("1000000", 18))
await swap.addOVELiquidity(ethers.parseUnits("1000000", 18))

// Step 6: Verify
const isSupported = await swap.supportedTokens(USDT_ADDRESS)
const isActive = await swap.isActive(USDT_ADDRESS)
const hasFeed = await swap.hasCustomPriceFeed(USDT_ADDRESS)

console.log("Token supported:", isSupported)
console.log("Token active:", isActive)
console.log("Has price feed:", hasFeed)

// Step 7: Test quote
const [oveAmount, feeAmount] = await swap.calculateBuyOVEWithFees(
    USDT_ADDRESS,
    ethers.parseUnits("100", 6)  // 100 USDT
)

console.log("100 USDT buys:", ethers.formatUnits(oveAmount, 18), "OVE")
console.log("Fee:", ethers.formatUnits(feeAmount, 6), "USDT")
```

---

## 🔍 Verification Checklist

After adding a token, verify:

- [ ] ✅ `supportedTokens[token]` returns `true`
- [ ] ✅ `isActive[token]` returns `true`
- [ ] ✅ `hasCustomPriceFeed[token]` returns `true` (if using Chainlink)
- [ ] ✅ `getPriceInfo(token)` returns correct prices
- [ ] ✅ Contract has sufficient token liquidity
- [ ] ✅ Contract has sufficient OVE liquidity
- [ ] ✅ Test buy OVE with token (small amount)
- [ ] ✅ Test sell OVE for token (small amount)
- [ ] ✅ Verify fees are sent to `feeRecipient`
- [ ] ✅ Verify price calculations are reasonable

---

## 🚨 Common Issues & Solutions

### **Issue 1: "Token not supported"**
**Solution:** Call `addSupportedToken()` first

### **Issue 2: "Invalid exchange rate"**
**Solution:** 
- Check if price feed is set correctly
- Or ensure manual rate is calculated properly

### **Issue 3: "Insufficient liquidity"**
**Solution:** Add more token and OVE liquidity via `addLiquidity()`

### **Issue 4: Prices seem wrong**
**Solution:**
- Verify Chainlink feed address is correct
- Check `getPriceInfo()` output
- Ensure OVE price is set via `setOVEPriceInUSD()`

### **Issue 5: "Price data too old"**
**Solution:** Chainlink price is stale (>1 hour). Wait for update or use manual rate.

---

## 📱 User Swap Flow (After Token Added)

Once token is added, users can swap:

### **Buy OVE with Token:**
```javascript
// User approves token spending
await token.approve(swapContract, amount)

// User buys OVE
await swap.buyOVE(tokenAddress, amount)
```

### **Sell OVE for Token:**
```javascript
// User approves OVE spending
await oveToken.approve(swapContract, amount)

// User sells OVE
await swap.sellOVE(tokenAddress, oveAmount)
```

---

## 🎯 Summary: Quick Reference

| Action | Function | When to Use |
|--------|----------|-------------|
| Add token with Chainlink | `addSupportedToken()` + `setPriceFeed()` | Major tokens |
| Add token manually | `addSupportedToken()` | Any token |
| Update OVE price | `setOVEPriceInUSD()` | When OVE price changes |
| Add liquidity | `addLiquidity()` | Before enabling swaps |
| Update manual rate | `updateExchangeRate()` | When token price changes |
| Pause trading | `pause(tokenAddress)` | Emergency |
| Resume trading | `unpause(tokenAddress)` | After issue resolved |
| Check status | `getPriceInfo()` | Debugging |

---

## 🎊 You're Ready!

Your new token is now integrated and users can swap it with OVE! 🚀

**Remember:**
- Keep sufficient liquidity for both tokens
- Monitor price feeds for accuracy
- Update manual rates regularly if not using Chainlink
- Test thoroughly before announcing to users

