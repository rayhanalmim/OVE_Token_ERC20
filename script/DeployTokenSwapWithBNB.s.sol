// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/OvenCoin.sol";
import "../src/TokenSwapWithNativeBNB.sol";

contract DeployTokenSwapWithBNB is Script {
    // Your deployed OVE token address
    address constant OVE_TOKEN_ADDRESS = 0x0eF7F6228dA35800B714C6E55c01f3d368B51942;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the enhanced TokenSwap contract with native BNB support
        TokenSwapWithNativeBNB swapContract = new TokenSwapWithNativeBNB(OVE_TOKEN_ADDRESS);
        
        console.log("=== Enhanced TokenSwap Deployment ===");
        console.log("OVE Token Address:", OVE_TOKEN_ADDRESS);
        console.log("TokenSwapWithNativeBNB deployed to:", address(swapContract));
        console.log("TokenSwap owner:", swapContract.owner());
        
        // Verify the connection
        CMCcoin oveToken = CMCcoin(OVE_TOKEN_ADDRESS);
        console.log("Connected OVE Token Name:", oveToken.name());
        console.log("Connected OVE Token Symbol:", oveToken.symbol());
        
        // Verify OVE token is automatically supported
        console.log("OVE Token automatically supported:", swapContract.supportedTokens(OVE_TOKEN_ADDRESS));
        console.log("OVE Token active status:", swapContract.isActive(OVE_TOKEN_ADDRESS));
        console.log("Native BNB address:", swapContract.NATIVE_BNB());
        
        vm.stopBroadcast();
    }
}

// Enhanced operations contract with native BNB support
contract TokenSwapWithBNBOperations is Script {
    // Update this after deployment
    address constant OVE_TOKEN_ADDRESS = 0x0eF7F6228dA35800B714C6E55c01f3d368B51942;
    address payable constant SWAP_CONTRACT_ADDRESS = payable(0x0Bd1c2f19A80A2Ad33E369A018A69D8606A11eB0); // Your deployed contract
    address constant NATIVE_BNB = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    // Add OVE liquidity
    function addOVELiquidity(uint256 amount) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        CMCcoin oveToken = CMCcoin(OVE_TOKEN_ADDRESS);
        
        // Approve and add OVE liquidity
        oveToken.approve(SWAP_CONTRACT_ADDRESS, amount);
        console.log("Approved OVE tokens for swap contract");
        
        swapContract.addOVELiquidity(amount);
        
        console.log("Added OVE liquidity amount:", amount);
        console.log("Current OVE balance in swap contract:", swapContract.getContractBalance(OVE_TOKEN_ADDRESS));
        
        vm.stopBroadcast();
    }
    
    // Add native BNB support
    function addNativeBNBSupport(uint256 rate) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        swapContract.addSupportedToken(NATIVE_BNB, rate, true);
        
        console.log("Added native BNB support");
        console.log("Exchange rate (1 OVE = X BNB):", rate);
        console.log("Active status: true");
        
        vm.stopBroadcast();
    }
    
    // Add native BNB liquidity
    function addBNBLiquidity() external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        
        // Send 0.1 tBNB (100000000000000000 wei)
        uint256 bnbAmount = 100000000000000000;
        swapContract.addBNBLiquidity{value: bnbAmount}();
        
        console.log("Added BNB liquidity amount:", bnbAmount, "wei (0.1 tBNB)");
        console.log("Current BNB balance in swap contract:", swapContract.getContractBalance(NATIVE_BNB));
        
        vm.stopBroadcast();
    }
    
    // Add ERC20 token support
    function addSupportedToken(address tokenAddress, uint256 rate, bool active) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        swapContract.addSupportedToken(tokenAddress, rate, active);
        
        console.log("Added supported token:", tokenAddress);
        console.log("Exchange rate (1 OVE = X tokens):", rate);
        console.log("Active status:", active);
        
        vm.stopBroadcast();
    }
    
    // Update exchange rate
    function updateExchangeRate(address tokenAddress, uint256 newRate) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        swapContract.updateExchangeRate(tokenAddress, newRate);
        
        console.log("Updated exchange rate for token:", tokenAddress);
        console.log("New rate (1 OVE = X tokens):", newRate);
        
        vm.stopBroadcast();
    }
    
    // CHAINLINK PRICE FEED FUNCTIONS
    
    // Add testnet tokens with Chainlink price feeds
    function addTestnetTokens(
        address wbnbAddress,
        address btcAddress, 
        address busdAddress
    ) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        swapContract.addTestnetTokens(wbnbAddress, btcAddress, busdAddress);
        
        console.log("Added testnet tokens with Chainlink price feeds:");
        console.log("WBNB:", wbnbAddress);
        console.log("BTC:", btcAddress);
        console.log("BUSD:", busdAddress);
        
        vm.stopBroadcast();
    }
    
    // Set OVE price in USD
    function setOVEPrice(uint256 priceInUSD) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        swapContract.setOVEPriceInUSD(priceInUSD);
        
        console.log("Set OVE price to (USD with 8 decimals):", priceInUSD);
        
        vm.stopBroadcast();
    }
    
    // Add price feed for a token
    function addPriceFeed(address tokenAddress, address priceFeedAddress) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        swapContract.setPriceFeed(tokenAddress, priceFeedAddress);
        
        console.log("Added price feed for token:", tokenAddress);
        console.log("Price feed address:", priceFeedAddress);
        
        vm.stopBroadcast();
    }
    
    // Toggle automatic pricing
    function toggleAutomaticPricing(bool enabled) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        swapContract.setAutomaticPricing(enabled);
        
        console.log("Automatic pricing enabled:", enabled);
        
        vm.stopBroadcast();
    }
    
    // Check prices and rates
    function checkPrices(address tokenAddress) external view {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        
        console.log("=== Price Information ===");
        console.log("Token address:", tokenAddress);
        
        (
            uint256 ovePriceUSD,
            uint256 tokenPriceUSD,
            uint256 exchangeRate,
            bool isAutomatic
        ) = swapContract.getPriceInfo(tokenAddress);
        
        console.log("OVE Price (USD, 8 decimals):", ovePriceUSD);
        console.log("Token Price (USD, 8 decimals):", tokenPriceUSD);
        console.log("Exchange Rate (18 decimals):", exchangeRate);
        console.log("Using automatic pricing:", isAutomatic);
        console.log("");
        console.log("=== Human Readable Prices ===");
        console.log("OVE Price: $", ovePriceUSD > 0 ? ovePriceUSD / 1e8 : 0, "USD");
        console.log("Token Price: $", tokenPriceUSD > 0 ? tokenPriceUSD / 1e8 : 0, "USD");
        console.log("Exchange Rate: 1 OVE =", exchangeRate > 0 ? exchangeRate / 1e18 : 0, "tokens");
        
        // Debug: Show raw values
        console.log("");
        console.log("=== DEBUG - Raw Values ===");
        console.log("Raw OVE Price:", ovePriceUSD);
        console.log("Raw Token Price:", tokenPriceUSD);
        console.log("Raw Exchange Rate:", exchangeRate);
        console.log("");
        console.log("=== Contract State ===");
        console.log("Native BNB Supported:", swapContract.supportedTokens(tokenAddress));
        console.log("Native BNB Active:", swapContract.isActive(tokenAddress));
        console.log("Has Price Feed:", swapContract.hasCustomPriceFeed(tokenAddress));
        console.log("Automatic Pricing Enabled:", swapContract.useAutomaticPricing());
        console.log("Manual Rate Override:", swapContract.useManualRate(tokenAddress));
    }
    
    // Check balances
    function checkBalances() external view {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        
        console.log("=== Enhanced TokenSwap Contract Balances ===");
        console.log("OVE Token Balance:", swapContract.getContractBalance(OVE_TOKEN_ADDRESS));
        console.log("Native BNB Balance:", swapContract.getContractBalance(NATIVE_BNB));
        console.log("Current OVE Price (USD):", swapContract.ovepriceInUSD());
        console.log("Automatic Pricing Enabled:", swapContract.useAutomaticPricing());
    }
    
    // Withdraw tokens
    function withdrawToken(address tokenAddress, uint256 amount, address to) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        swapContract.withdrawToken(tokenAddress, amount, to);
        
        console.log("Withdrawn token:", tokenAddress);
        console.log("Amount:", amount);
        console.log("To wallet:", to);
        
        vm.stopBroadcast();
    }
    
    // Emergency withdraw all
    function emergencyWithdrawAll(address to) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        swapContract.emergencyWithdrawAll(to);
        
        console.log("Emergency withdrawal completed to:", to);
        
        vm.stopBroadcast();
    }
    
    // SWAP FUNCTIONS
    
    // Buy OVE with native BNB (convenience function)
    function buyOVEWithBNB() external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        
        // Send 0.01 tBNB (10000000000000000 wei)
        uint256 bnbAmount = 10000000000000000;
        swapContract.buyOVEWithBNB{value: bnbAmount}();
        
        console.log("Bought OVE with BNB amount:", bnbAmount, "wei (0.01 tBNB)");
        console.log("Current BNB balance in swap contract:", swapContract.getContractBalance(NATIVE_BNB));
        
        vm.stopBroadcast();
    }
    
    // Get swap quote (view function - no transaction needed)
    function getSwapQuote(address tokenIn, address tokenOut, uint256 amountIn) external view {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        uint256 amountOut = swapContract.getSwapQuote(tokenIn, tokenOut, amountIn);
        
        // Get detailed price information
        (uint256 ovePriceUSD, uint256 tokenPriceUSD, uint256 exchangeRate, bool isAutomatic) = swapContract.getPriceInfo(tokenIn);
        
        console.log("=== DETAILED SWAP QUOTE ===");
        console.log("Token In:", tokenIn);
        console.log("Token Out:", tokenOut);
        console.log("Amount In:", amountIn, "wei");
        console.log("Amount Out:", amountOut, "wei");
        console.log("");
        console.log("=== PRICING INFORMATION ===");
        console.log("OVE Price (USD):", ovePriceUSD, "wei (8 decimals)");
        console.log("Token Price (USD):", tokenPriceUSD, "wei (8 decimals)");
        console.log("Exchange Rate:", exchangeRate, "wei (18 decimals)");
        console.log("Using Automatic Pricing:", isAutomatic);
        console.log("");
        console.log("=== CONVERSION RATES ===");
        console.log("1 OVE =", (exchangeRate / 1e18), "tokens");
        console.log("1 Token =", (1e18 * 1e18) / exchangeRate, "wei OVE");
        console.log("Rate (OVE per token):", (amountOut * 1e18) / amountIn, "wei");
        
        // Convert to human readable format
        console.log("");
        console.log("=== HUMAN READABLE ===");
        console.log("Amount In (BNB):", amountIn / 1e18, "BNB");
        console.log("Amount Out (OVE):", amountOut / 1e18, "OVE");
        console.log("OVE Price: $", ovePriceUSD / 1e8, "USD");
        console.log("BNB Price: $", tokenPriceUSD / 1e8, "USD");
    }
    
    // Buy OVE with any token
    function buyOVE(address tokenIn, uint256 amountIn) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        
        if (tokenIn == NATIVE_BNB) {
            // For native BNB, send value with transaction
            swapContract.buyOVE{value: amountIn}(tokenIn, amountIn);
            console.log("Bought OVE with native BNB:", amountIn, "wei");
        } else {
            // For ERC20 tokens, no value needed
            swapContract.buyOVE(tokenIn, amountIn);
            console.log("Bought OVE with ERC20 token:", tokenIn);
            console.log("Amount:", amountIn, "wei");
        }
        
        vm.stopBroadcast();
    }
    
    // DEBUG: Check Chainlink feed directly
    function debugChainlinkFeed(address tokenAddress) external view {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        
        console.log("=== CHAINLINK FEED DEBUG ===");
        console.log("Token:", tokenAddress);
        console.log("Has Price Feed:", swapContract.hasCustomPriceFeed(tokenAddress));
        
        // Get OVE price first
        uint256 ovePrice = swapContract.ovepriceInUSD();
        console.log("OVE Price (8 decimals):", ovePrice);
        console.log("OVE Price (USD):", ovePrice / 1e8);
        
        // Check contract state
        console.log("Automatic Pricing:", swapContract.useAutomaticPricing());
        console.log("Manual Rate Override:", swapContract.useManualRate(tokenAddress));
        console.log("Token Supported:", swapContract.supportedTokens(tokenAddress));
        console.log("Token Active:", swapContract.isActive(tokenAddress));
        
        // Get exchange rate directly
        uint256 exchangeRate = swapContract.exchangeRates(tokenAddress);
        console.log("Manual Exchange Rate (18 decimals):", exchangeRate);
        console.log("Manual Exchange Rate (human):", exchangeRate / 1e18);
    }
    
    // Simple price check without try-catch
    function simplePriceCheck() external view {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        
        TokenSwapWithNativeBNB swapContract = TokenSwapWithNativeBNB(payable(SWAP_CONTRACT_ADDRESS));
        
        console.log("=== SIMPLE PRICE CHECK ===");
        
        uint256 ovePrice = swapContract.ovepriceInUSD();
        console.log("OVE Price:", ovePrice);
        console.log("OVE Price (USD):", ovePrice / 1e8);
        
        console.log("Automatic Pricing:", swapContract.useAutomaticPricing());
        console.log("Native BNB Supported:", swapContract.supportedTokens(NATIVE_BNB));
        console.log("Native BNB Active:", swapContract.isActive(NATIVE_BNB));
        console.log("Has Price Feed:", swapContract.hasCustomPriceFeed(NATIVE_BNB));
        
        uint256 manualRate = swapContract.exchangeRates(NATIVE_BNB);
        console.log("Manual Rate:", manualRate);
        console.log("Manual Rate (human):", manualRate / 1e18);
        
        // Check if prices are 0
        if (ovePrice == 0) {
            console.log("WARNING: OVE Price is 0 - need to set it!");
        }
        if (manualRate == 0) {
            console.log("WARNING: Manual Rate is 0 - need to set it!");
        }
    }
}
