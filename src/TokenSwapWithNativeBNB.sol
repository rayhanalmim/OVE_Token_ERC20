// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./OvenCoin.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// Chainlink Price Feed Interface
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract TokenSwapWithNativeBNB is Ownable, ReentrancyGuard {
    CMCcoin public immutable oveToken;
    
    // Special address to represent native BNB
    address public constant NATIVE_BNB = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    
    // Supported tokens for swap (including native BNB)
    mapping(address => bool) public supportedTokens;
    mapping(address => uint256) public exchangeRates; // Rate: 1 OVE = X tokens (DEPRECATED - now calculated dynamically)
    mapping(address => bool) public isActive; // Token swap status
    
    // Chainlink Price Feed Integration
    mapping(address => AggregatorV3Interface) public priceFeeds; // Token => Price Feed
    mapping(address => bool) public hasCustomPriceFeed; // Whether token has Chainlink feed
    
    // OVE Pricing
    uint256 public ovepriceInUSD; // OVE price in USD (8 decimals) - set by admin
    bool public useAutomaticPricing = true; // Use Chainlink feeds vs manual rates
    
    // Swap Fee System (in basis points: 100 = 1%, 10000 = 100%)
    uint256 public swapFeeBuyBPS = 30; // Default 0.3% fee for buying OVE
    uint256 public swapFeeSellBPS = 30; // Default 0.3% fee for selling OVE
    uint256 public constant MAX_SWAP_FEE_BPS = 1000; // Maximum 10% fee
    uint256 public constant BPS_DENOMINATOR = 10000; // Basis points denominator
    
    // Fee Recipient (fees sent immediately on each swap)
    address public feeRecipient; // Address to receive fees
    
    // Price feed constants - can be updated for different networks
    // BSC Mainnet Chainlink Price Feeds:
    address public constant BNB_USD_MAINNET = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; // BNB/USD on BSC Mainnet
    address public constant ETH_USD_MAINNET = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e; // ETH/USD on BSC Mainnet
    address public constant BTC_USD_MAINNET = 0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf; // BTC/USD on BSC Mainnet
    address public constant USDT_USD_MAINNET = 0xB97Ad0E74fa7d920791E90258A6E2085088b4320; // USDT/USD on BSC Mainnet
    
    // BSC Testnet Price Feeds (Official Chainlink addresses):
    address public constant BNB_USD_TESTNET = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526; // BNB/USD on BSC Testnet
    address public constant BTC_USD_TESTNET = 0x5741306c21795FdCBb9b265Ea0255F499DFe515C; // BTC/USD on BSC Testnet  
    address public constant BUSD_USD_TESTNET = 0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa; // BUSD/USD on BSC Testnet
    address public constant AAVE_USD_TESTNET = 0x298619601ebCd58d0b526963Deb2365B485Edc74; // AAVE/USD on BSC Testnet
    address public constant ADA_USD_TESTNET = 0x5e66a1775BbC249b5D51C13d29245522582E671C; // ADA/USD on BSC Testnet
    
    // Emergency manual override
    mapping(address => bool) public useManualRate; // Override automatic pricing for specific tokens
    
    // Events
    event TokenSwapped(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    
    event ExchangeRateUpdated(address indexed token, uint256 newRate);
    event TokenSupportUpdated(address indexed token, bool supported);
    event LiquidityAdded(address indexed token, uint256 amount);
    event LiquidityRemoved(address indexed token, uint256 amount);
    event OVEPriceUpdated(uint256 newPriceInUSD);
    event PriceFeedUpdated(address indexed token, address indexed priceFeed);
    event AutomaticPricingToggled(bool enabled);
    event ManualRateOverride(address indexed token, bool useManual);
    event SwapFeesUpdated(uint256 buyFeeBPS, uint256 sellFeeBPS);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event FeePaid(address indexed token, address indexed recipient, uint256 amount);
    
    constructor(address _oveToken, address _feeRecipient) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        
        oveToken = CMCcoin(_oveToken);
        feeRecipient = _feeRecipient;
        
        // Automatically add OVE token as supported
        supportedTokens[_oveToken] = true;
        exchangeRates[_oveToken] = 1e18; // Kept for backward compatibility
        isActive[_oveToken] = true;
        
        // Initialize price feeds (use testnet for now - update for mainnet)
        priceFeeds[NATIVE_BNB] = AggregatorV3Interface(BNB_USD_TESTNET);
        hasCustomPriceFeed[NATIVE_BNB] = true;
        
        // Set default OVE price to $0.01 USD (1 cent)
        ovepriceInUSD = 1000000; // 0.01 USD with 8 decimals
        
        emit TokenSupportUpdated(_oveToken, true);
        emit ExchangeRateUpdated(_oveToken, 1e18);
        emit OVEPriceUpdated(ovepriceInUSD);
        emit PriceFeedUpdated(NATIVE_BNB, BNB_USD_TESTNET);
        emit SwapFeesUpdated(swapFeeBuyBPS, swapFeeSellBPS);
        emit FeeRecipientUpdated(address(0), _feeRecipient);
    }
    
    // Allow contract to receive native BNB
    receive() external payable {}
    
    // =================================================================================
    // CHAINLINK PRICE FEED FUNCTIONS
    // =================================================================================
    
    /**
     * @dev Set OVE price in USD (only admin)
     * @param _priceInUSD Price in USD with 8 decimals (e.g., 1000000 = $0.01)
     */
    function setOVEPriceInUSD(uint256 _priceInUSD) external onlyOwner {
        require(_priceInUSD > 0, "Price must be greater than 0");
        ovepriceInUSD = _priceInUSD;
        emit OVEPriceUpdated(_priceInUSD);
    }
    
    /**
     * @dev Add or update price feed for a token
     * @param token Token address
     * @param priceFeed Chainlink price feed address
     */
    function setPriceFeed(address token, address priceFeed) external onlyOwner {
        require(priceFeed != address(0), "Invalid price feed address");
        priceFeeds[token] = AggregatorV3Interface(priceFeed);
        hasCustomPriceFeed[token] = true;
        emit PriceFeedUpdated(token, priceFeed);
    }
    
    /**
     * @dev Toggle automatic pricing on/off
     * @param _enabled True to use Chainlink feeds, false for manual rates
     */
    function setAutomaticPricing(bool _enabled) external onlyOwner {
        useAutomaticPricing = _enabled;
        emit AutomaticPricingToggled(_enabled);
    }
    
    /**
     * @dev Override automatic pricing for specific token
     * @param token Token address
     * @param _useManual True to use manual rate, false to use Chainlink
     */
    function setManualRateOverride(address token, bool _useManual) external onlyOwner {
        useManualRate[token] = _useManual;
        emit ManualRateOverride(token, _useManual);
    }
    
    /**
     * @dev Configure contract for mainnet (admin function)
     * Call this after deploying to mainnet to switch to mainnet price feeds
     */
    function configureForMainnet() external onlyOwner {
        // Update to mainnet price feeds
        priceFeeds[NATIVE_BNB] = AggregatorV3Interface(BNB_USD_MAINNET);
        hasCustomPriceFeed[NATIVE_BNB] = true;
        
        emit PriceFeedUpdated(NATIVE_BNB, BNB_USD_MAINNET);
    }
    
    /**
     * @dev Add common testnet tokens with their price feeds
     * Call this to quickly setup major tokens for BSC testnet
     */
    function addTestnetTokens(
        address wbnbAddress,
        address btcAddress,
        address busdAddress
    ) external onlyOwner {
        // Add WBNB with BNB price feed
        if (wbnbAddress != address(0)) {
            supportedTokens[wbnbAddress] = true;
            isActive[wbnbAddress] = true;
            priceFeeds[wbnbAddress] = AggregatorV3Interface(BNB_USD_TESTNET);
            hasCustomPriceFeed[wbnbAddress] = true;
            emit TokenSupportUpdated(wbnbAddress, true);
            emit PriceFeedUpdated(wbnbAddress, BNB_USD_TESTNET);
        }
        
        // Add BTC with BTC price feed
        if (btcAddress != address(0)) {
            supportedTokens[btcAddress] = true;
            isActive[btcAddress] = true;
            priceFeeds[btcAddress] = AggregatorV3Interface(BTC_USD_TESTNET);
            hasCustomPriceFeed[btcAddress] = true;
            emit TokenSupportUpdated(btcAddress, true);
            emit PriceFeedUpdated(btcAddress, BTC_USD_TESTNET);
        }
        
        // Add BUSD with BUSD price feed
        if (busdAddress != address(0)) {
            supportedTokens[busdAddress] = true;
            isActive[busdAddress] = true;
            priceFeeds[busdAddress] = AggregatorV3Interface(BUSD_USD_TESTNET);
            hasCustomPriceFeed[busdAddress] = true;
            emit TokenSupportUpdated(busdAddress, true);
            emit PriceFeedUpdated(busdAddress, BUSD_USD_TESTNET);
        }
    }
    
    /**
     * @dev Add common mainnet tokens with their price feeds
     * Call this to quickly setup major tokens for mainnet
     */
    function addMainnetTokens(
        address wbnbAddress,
        address ethAddress, 
        address btcAddress,
        address usdtAddress
    ) external onlyOwner {
        // Add WBNB with BNB price feed
        if (wbnbAddress != address(0)) {
            supportedTokens[wbnbAddress] = true;
            isActive[wbnbAddress] = true;
            priceFeeds[wbnbAddress] = AggregatorV3Interface(BNB_USD_MAINNET);
            hasCustomPriceFeed[wbnbAddress] = true;
            emit TokenSupportUpdated(wbnbAddress, true);
            emit PriceFeedUpdated(wbnbAddress, BNB_USD_MAINNET);
        }
        
        // Add ETH with ETH price feed
        if (ethAddress != address(0)) {
            supportedTokens[ethAddress] = true;
            isActive[ethAddress] = true;
            priceFeeds[ethAddress] = AggregatorV3Interface(ETH_USD_MAINNET);
            hasCustomPriceFeed[ethAddress] = true;
            emit TokenSupportUpdated(ethAddress, true);
            emit PriceFeedUpdated(ethAddress, ETH_USD_MAINNET);
        }
        
        // Add BTC with BTC price feed
        if (btcAddress != address(0)) {
            supportedTokens[btcAddress] = true;
            isActive[btcAddress] = true;
            priceFeeds[btcAddress] = AggregatorV3Interface(BTC_USD_MAINNET);
            hasCustomPriceFeed[btcAddress] = true;
            emit TokenSupportUpdated(btcAddress, true);
            emit PriceFeedUpdated(btcAddress, BTC_USD_MAINNET);
        }
        
        // Add USDT with USDT price feed
        if (usdtAddress != address(0)) {
            supportedTokens[usdtAddress] = true;
            isActive[usdtAddress] = true;
            priceFeeds[usdtAddress] = AggregatorV3Interface(USDT_USD_MAINNET);
            hasCustomPriceFeed[usdtAddress] = true;
            emit TokenSupportUpdated(usdtAddress, true);
            emit PriceFeedUpdated(usdtAddress, USDT_USD_MAINNET);
        }
    }
    
    /**
     * @dev Get current USD price for any token from Chainlink
     * @param token Token address
     * @return price Price in USD with 8 decimals
     */
    function getTokenPriceInUSD(address token) public view returns (uint256 price) {
        if (!hasCustomPriceFeed[token]) {
            return 0; // No price feed available
        }
        
        AggregatorV3Interface priceFeed = priceFeeds[token];
        (
            uint80 roundID, 
            int256 tokenPrice,
            ,  // startedAt not needed
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        
        require(tokenPrice > 0, "Invalid price from feed");
        require(timeStamp > 0, "Incomplete round");
        require(answeredInRound >= roundID, "Stale price data");
        
        // Check if price is not too old (1 hour staleness check)
        require(block.timestamp - timeStamp < 3600, "Price data too old");
        
        // Price feeds return prices with 8 decimals
        return uint256(tokenPrice);
    }
    
    /**
     * @dev Calculate dynamic exchange rate: 1 OVE = X tokens
     * @param token Token address
     * @return rate Exchange rate with 18 decimals
     */
    function getDynamicExchangeRate(address token) public view returns (uint256 rate) {
        // If manual override is enabled for this token, use stored rate
        if (useManualRate[token] || !useAutomaticPricing) {
            return exchangeRates[token];
        }
        
        // If no price feed available, fall back to manual rate
        if (!hasCustomPriceFeed[token]) {
            return exchangeRates[token];
        }
        
        // Get current market price for the token
        uint256 tokenPriceInUSD = getTokenPriceInUSD(token);
        if (tokenPriceInUSD == 0) {
            return exchangeRates[token]; // Fallback to manual rate
        }
        
        // Calculate rate: (OVE_PRICE_USD / TOKEN_PRICE_USD) * 10^18
        // Both prices have 8 decimals, so we need to adjust for 18 decimal output
        rate = (ovepriceInUSD * 1e18) / tokenPriceInUSD;
        
        return rate;
    }
    
    /**
     * @dev Get comprehensive price info for debugging
     * @param token Token address
     * @return ovePriceUSD Current OVE price in USD (8 decimals)
     * @return tokenPriceUSD Current token price in USD (8 decimals)  
     * @return exchangeRate Current exchange rate (18 decimals)
     * @return isAutomatic Whether using automatic pricing
     */
    function getPriceInfo(address token) external view returns (
        uint256 ovePriceUSD,
        uint256 tokenPriceUSD,
        uint256 exchangeRate,
        bool isAutomatic
    ) {
        ovePriceUSD = ovepriceInUSD;
        tokenPriceUSD = hasCustomPriceFeed[token] ? getTokenPriceInUSD(token) : 0;
        exchangeRate = getDynamicExchangeRate(token);
        isAutomatic = useAutomaticPricing && !useManualRate[token] && hasCustomPriceFeed[token];
    }
    
    // =================================================================================
    // FEE MANAGEMENT FUNCTIONS
    // =================================================================================
    
    /**
     * @dev Set swap fees for buying and selling OVE
     * @param _buyFeeBPS Buy fee in basis points (100 = 1%)
     * @param _sellFeeBPS Sell fee in basis points (100 = 1%)
     */
    function setSwapFees(uint256 _buyFeeBPS, uint256 _sellFeeBPS) external onlyOwner {
        require(_buyFeeBPS <= MAX_SWAP_FEE_BPS, "Buy fee too high");
        require(_sellFeeBPS <= MAX_SWAP_FEE_BPS, "Sell fee too high");
        
        swapFeeBuyBPS = _buyFeeBPS;
        swapFeeSellBPS = _sellFeeBPS;
        
        emit SwapFeesUpdated(_buyFeeBPS, _sellFeeBPS);
    }
    
    /**
     * @dev Set buy fee only
     * @param _buyFeeBPS Buy fee in basis points (100 = 1%)
     */
    function setBuyFee(uint256 _buyFeeBPS) external onlyOwner {
        require(_buyFeeBPS <= MAX_SWAP_FEE_BPS, "Buy fee too high");
        swapFeeBuyBPS = _buyFeeBPS;
        emit SwapFeesUpdated(swapFeeBuyBPS, swapFeeSellBPS);
    }
    
    /**
     * @dev Set sell fee only
     * @param _sellFeeBPS Sell fee in basis points (100 = 1%)
     */
    function setSellFee(uint256 _sellFeeBPS) external onlyOwner {
        require(_sellFeeBPS <= MAX_SWAP_FEE_BPS, "Sell fee too high");
        swapFeeSellBPS = _sellFeeBPS;
        emit SwapFeesUpdated(swapFeeBuyBPS, swapFeeSellBPS);
    }
    
    /**
     * @dev Set fee recipient address
     * @param _feeRecipient New fee recipient address
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        address oldRecipient = feeRecipient;
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(oldRecipient, _feeRecipient);
    }
    
    /**
     * @dev Calculate fee amount
     * @param amount Input amount
     * @param feeBPS Fee in basis points
     * @return feeAmount Fee to be collected
     */
    function calculateFee(uint256 amount, uint256 feeBPS) public pure returns (uint256) {
        return (amount * feeBPS) / BPS_DENOMINATOR;
    }
    
    // =================================================================================
    // ADMIN FUNCTIONS (UPDATED FOR CHAINLINK)
    // =================================================================================
    function addSupportedToken(
        address token,
        uint256 rate,
        bool active
    ) external onlyOwner {
        supportedTokens[token] = true;
        exchangeRates[token] = rate;
        isActive[token] = active;
        emit TokenSupportUpdated(token, true);
        emit ExchangeRateUpdated(token, rate);
    }
    
    function updateExchangeRate(address token, uint256 newRate) external onlyOwner {
        require(supportedTokens[token], "Token not supported");
        exchangeRates[token] = newRate;
        emit ExchangeRateUpdated(token, newRate);
    }
    
    function toggleTokenStatus(address token) external onlyOwner {
        require(supportedTokens[token], "Token not supported");
        isActive[token] = !isActive[token];
    }
    
    // Enhanced addLiquidity - supports both ERC20 and native BNB
    function addLiquidity(address token, uint256 amount) external payable onlyOwner {
        require(supportedTokens[token], "Token not supported");
        
        if (token == NATIVE_BNB) {
            require(msg.value == amount, "BNB amount mismatch");
            require(amount > 0, "Amount must be greater than 0");
        } else if (token == address(oveToken)) {
            require(msg.value == 0, "Don't send BNB for OVE");
            require(oveToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        } else {
            require(msg.value == 0, "Don't send BNB for ERC20");
            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        }
        
        emit LiquidityAdded(token, amount);
    }
    
    // Add native BNB liquidity (payable function)
    function addBNBLiquidity() external payable onlyOwner {
        require(supportedTokens[NATIVE_BNB], "Native BNB not supported");
        require(msg.value > 0, "Must send BNB");
        
        emit LiquidityAdded(NATIVE_BNB, msg.value);
    }
    
    // Dedicated OVE liquidity function
    function addOVELiquidity(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(oveToken.transferFrom(msg.sender, address(this), amount), "OVE transfer failed");
        
        emit LiquidityAdded(address(oveToken), amount);
    }
    
    // Enhanced removeLiquidity - supports both ERC20 and native BNB
    function removeLiquidity(address token, uint256 amount) external onlyOwner {
        if (token == NATIVE_BNB) {
            require(address(this).balance >= amount, "Insufficient BNB balance");
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "BNB transfer failed");
        } else if (token == address(oveToken)) {
            require(oveToken.transfer(msg.sender, amount), "Transfer failed");
        } else {
            require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        }
        
        emit LiquidityRemoved(token, amount);
    }
    
    // Buy OVE with any supported token (including native BNB)
    function buyOVE(address tokenIn, uint256 amountIn) external payable nonReentrant {
        require(supportedTokens[tokenIn], "Token not supported");
        require(isActive[tokenIn], "Token swap not active");
        require(amountIn > 0, "Amount must be greater than 0");
        
        // Calculate fee on input token
        uint256 feeAmount = calculateFee(amountIn, swapFeeBuyBPS);
        uint256 amountAfterFee = amountIn - feeAmount;
        
        uint256 oveAmount = calculateOVEOutput(tokenIn, amountAfterFee);
        require(oveAmount > 0, "Invalid swap amount");
        require(oveToken.balanceOf(address(this)) >= oveAmount, "Insufficient OVE liquidity");
        
        // Handle input token transfer
        if (tokenIn == NATIVE_BNB) {
            require(msg.value == amountIn, "BNB amount mismatch");
            
            // Send fee directly to recipient
            if (feeAmount > 0) {
                (bool feeSuccess, ) = payable(feeRecipient).call{value: feeAmount}("");
                require(feeSuccess, "Fee transfer failed");
                emit FeePaid(tokenIn, feeRecipient, feeAmount);
            }
        } else {
            require(msg.value == 0, "Don't send BNB for ERC20");
            require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
            
            // Send fee directly to recipient
            if (feeAmount > 0) {
                require(IERC20(tokenIn).transfer(feeRecipient, feeAmount), "Fee transfer failed");
                emit FeePaid(tokenIn, feeRecipient, feeAmount);
            }
        }
        
        // Transfer OVE to user
        require(oveToken.transfer(msg.sender, oveAmount), "OVE transfer failed");
        
        emit TokenSwapped(msg.sender, tokenIn, address(oveToken), amountIn, oveAmount);
    }
    
    // Sell OVE for any supported token (including native BNB)
    function sellOVE(address tokenOut, uint256 oveAmount) external nonReentrant {
        require(supportedTokens[tokenOut], "Token not supported");
        require(isActive[tokenOut], "Token swap not active");
        require(oveAmount > 0, "Amount must be greater than 0");
        
        uint256 tokenAmount = calculateTokenOutput(tokenOut, oveAmount);
        require(tokenAmount > 0, "Invalid swap amount");
        
        // Calculate fee on output token
        uint256 feeAmount = calculateFee(tokenAmount, swapFeeSellBPS);
        uint256 tokenAmountAfterFee = tokenAmount - feeAmount;
        
        // Check liquidity (including fee)
        if (tokenOut == NATIVE_BNB) {
            require(address(this).balance >= tokenAmount, "Insufficient BNB liquidity");
        } else {
            require(IERC20(tokenOut).balanceOf(address(this)) >= tokenAmount, "Insufficient token liquidity");
        }
        
        // Transfer OVE from user to contract
        require(oveToken.transferFrom(msg.sender, address(this), oveAmount), "OVE transfer failed");
        
        // Transfer output token to user and fee to recipient
        if (tokenOut == NATIVE_BNB) {
            // Transfer to user
            (bool success, ) = payable(msg.sender).call{value: tokenAmountAfterFee}("");
            require(success, "BNB transfer failed");
            
            // Send fee to recipient
            if (feeAmount > 0) {
                (bool feeSuccess, ) = payable(feeRecipient).call{value: feeAmount}("");
                require(feeSuccess, "Fee transfer failed");
                emit FeePaid(tokenOut, feeRecipient, feeAmount);
            }
        } else {
            // Transfer to user
            require(IERC20(tokenOut).transfer(msg.sender, tokenAmountAfterFee), "Token transfer failed");
            
            // Send fee to recipient
            if (feeAmount > 0) {
                require(IERC20(tokenOut).transfer(feeRecipient, feeAmount), "Fee transfer failed");
                emit FeePaid(tokenOut, feeRecipient, feeAmount);
            }
        }
        
        emit TokenSwapped(msg.sender, address(oveToken), tokenOut, oveAmount, tokenAmountAfterFee);
    }
    
    // Buy OVE with native BNB (convenience function)
    function buyOVEWithBNB() external payable nonReentrant {
        require(supportedTokens[NATIVE_BNB], "Native BNB not supported");
        require(isActive[NATIVE_BNB], "BNB swap not active");
        require(msg.value > 0, "Must send BNB");
        
        // Calculate fee on input BNB
        uint256 feeAmount = calculateFee(msg.value, swapFeeBuyBPS);
        uint256 amountAfterFee = msg.value - feeAmount;
        
        uint256 oveAmount = calculateOVEOutput(NATIVE_BNB, amountAfterFee);
        require(oveAmount > 0, "Invalid swap amount");
        require(oveToken.balanceOf(address(this)) >= oveAmount, "Insufficient OVE liquidity");
        
        // Send fee directly to recipient
        if (feeAmount > 0) {
            (bool feeSuccess, ) = payable(feeRecipient).call{value: feeAmount}("");
            require(feeSuccess, "Fee transfer failed");
            emit FeePaid(NATIVE_BNB, feeRecipient, feeAmount);
        }
        
        // Transfer OVE to user
        require(oveToken.transfer(msg.sender, oveAmount), "OVE transfer failed");
        
        emit TokenSwapped(msg.sender, NATIVE_BNB, address(oveToken), msg.value, oveAmount);
    }
    
    // Calculate OVE output for given input token amount (UPDATED FOR CHAINLINK)
    function calculateOVEOutput(address tokenIn, uint256 amountIn) public view returns (uint256) {
        require(supportedTokens[tokenIn], "Token not supported");
        
        // Use dynamic exchange rate from Chainlink or manual fallback
        uint256 rate = getDynamicExchangeRate(tokenIn);
        require(rate > 0, "Invalid exchange rate");
        
        return (amountIn * 1e18) / rate;
    }
    
    // Calculate token output for given OVE amount (UPDATED FOR CHAINLINK)
    function calculateTokenOutput(address tokenOut, uint256 oveAmount) public view returns (uint256) {
        require(supportedTokens[tokenOut], "Token not supported");
        
        // Use dynamic exchange rate from Chainlink or manual fallback
        uint256 rate = getDynamicExchangeRate(tokenOut);
        require(rate > 0, "Invalid exchange rate");
        
        return (oveAmount * rate) / 1e18;
    }
    
    /**
     * @dev Calculate OVE output including fees for buying
     * @param tokenIn Input token address
     * @param amountIn Input amount
     * @return oveAmount OVE amount after fees
     * @return feeAmount Fee amount in input token
     */
    function calculateBuyOVEWithFees(address tokenIn, uint256 amountIn) 
        external 
        view 
        returns (uint256 oveAmount, uint256 feeAmount) 
    {
        feeAmount = calculateFee(amountIn, swapFeeBuyBPS);
        uint256 amountAfterFee = amountIn - feeAmount;
        oveAmount = calculateOVEOutput(tokenIn, amountAfterFee);
    }
    
    /**
     * @dev Calculate token output including fees for selling OVE
     * @param tokenOut Output token address
     * @param oveAmount OVE amount to sell
     * @return tokenAmount Token amount after fees
     * @return feeAmount Fee amount in output token
     */
    function calculateSellOVEWithFees(address tokenOut, uint256 oveAmount) 
        external 
        view 
        returns (uint256 tokenAmount, uint256 feeAmount) 
    {
        uint256 tokenAmountBeforeFee = calculateTokenOutput(tokenOut, oveAmount);
        feeAmount = calculateFee(tokenAmountBeforeFee, swapFeeSellBPS);
        tokenAmount = tokenAmountBeforeFee - feeAmount;
    }
    
    // Enhanced getContractBalance - supports both ERC20 and native BNB
    function getContractBalance(address token) external view returns (uint256) {
        if (token == NATIVE_BNB) {
            return address(this).balance;
        } else if (token == address(oveToken)) {
            return oveToken.balanceOf(address(this));
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
    
    // Enhanced swap quote
    function getSwapQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        if (tokenIn == address(oveToken)) {
            amountOut = calculateTokenOutput(tokenOut, amountIn);
        } else if (tokenOut == address(oveToken)) {
            amountOut = calculateOVEOutput(tokenIn, amountIn);
        } else {
            // Token to token swap (via OVE)
            uint256 oveAmount = calculateOVEOutput(tokenIn, amountIn);
            amountOut = calculateTokenOutput(tokenOut, oveAmount);
        }
    }
    
    // Withdraw any token including native BNB
    function withdrawToken(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        
        if (token == NATIVE_BNB) {
            require(address(this).balance >= amount, "Insufficient BNB balance");
            (bool success, ) = payable(to).call{value: amount}("");
            require(success, "BNB transfer failed");
        } else if (token == address(oveToken)) {
            require(oveToken.balanceOf(address(this)) >= amount, "Insufficient OVE balance");
            require(oveToken.transfer(to, amount), "OVE transfer failed");
        } else {
            require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient token balance");
            require(IERC20(token).transfer(to, amount), "Token transfer failed");
        }
        
        emit LiquidityRemoved(token, amount);
    }
    
    // Emergency withdraw all funds including BNB
    function emergencyWithdrawAll(address to) external onlyOwner {
        require(to != address(0), "Invalid recipient address");
        
        // Withdraw all OVE tokens
        uint256 oveBalance = oveToken.balanceOf(address(this));
        if (oveBalance > 0) {
            require(oveToken.transfer(to, oveBalance), "OVE transfer failed");
            emit LiquidityRemoved(address(oveToken), oveBalance);
        }
        
        // Withdraw all native BNB
        uint256 bnbBalance = address(this).balance;
        if (bnbBalance > 0) {
            (bool success, ) = payable(to).call{value: bnbBalance}("");
            require(success, "BNB transfer failed");
            emit LiquidityRemoved(NATIVE_BNB, bnbBalance);
        }
    }
    
    // Emergency functions
    function emergencyWithdraw(address token) external onlyOwner {
        if (token == NATIVE_BNB) {
            uint256 balance = address(this).balance;
            (bool success, ) = payable(msg.sender).call{value: balance}("");
            require(success, "BNB transfer failed");
        } else if (token == address(oveToken)) {
            uint256 balance = oveToken.balanceOf(address(this));
            require(oveToken.transfer(msg.sender, balance), "Transfer failed");
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            require(IERC20(token).transfer(msg.sender, balance), "Transfer failed");
        }
    }
    
    function pause(address token) external onlyOwner {
        isActive[token] = false;
    }
    
    function unpause(address token) external onlyOwner {
        require(supportedTokens[token], "Token not supported");
        isActive[token] = true;
    }
}
