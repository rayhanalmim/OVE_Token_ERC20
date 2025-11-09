// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./OvenCoin.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenSwap is Ownable, ReentrancyGuard {
    CMCcoin public immutable oveToken;
    
    // Supported tokens for swap
    mapping(address => bool) public supportedTokens;
    mapping(address => uint256) public exchangeRates; // Rate: 1 OVE = X tokens
    mapping(address => bool) public isActive; // Token swap status
    
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
    
    constructor(address _oveToken) {
        oveToken = CMCcoin(_oveToken);
        
        // Automatically add OVE token as supported with 1:1 rate for initialization
        // This allows adding OVE liquidity immediately after deployment
        supportedTokens[_oveToken] = true;
        exchangeRates[_oveToken] = 1e18; // 1:1 rate initially (can be updated later)
        isActive[_oveToken] = true;
        
        emit TokenSupportUpdated(_oveToken, true);
        emit ExchangeRateUpdated(_oveToken, 1e18);
    }
    
    // Admin Functions
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
    
    // Add liquidity (Admin deposits tokens to contract)
    function addLiquidity(address token, uint256 amount) external onlyOwner {
        require(supportedTokens[token], "Token not supported");
        
        if (token == address(oveToken)) {
            require(oveToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        } else {
            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        }
        
        emit LiquidityAdded(token, amount);
    }

    // Dedicated function to add OVE token liquidity (doesn't require supportedTokens check)
    function addOVELiquidity(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(oveToken.transferFrom(msg.sender, address(this), amount), "OVE transfer failed");
        
        emit LiquidityAdded(address(oveToken), amount);
    }

    // Dedicated function to remove OVE token liquidity
    function removeOVELiquidity(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(oveToken.balanceOf(address(this)) >= amount, "Insufficient OVE balance");
        require(oveToken.transfer(msg.sender, amount), "OVE transfer failed");
        
        emit LiquidityRemoved(address(oveToken), amount);
    }
    
    // Remove liquidity (Admin withdraws tokens from contract)
    function removeLiquidity(address token, uint256 amount) external onlyOwner {
        if (token == address(oveToken)) {
            require(oveToken.transfer(msg.sender, amount), "Transfer failed");
        } else {
            require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        }
        
        emit LiquidityRemoved(token, amount);
    }
    
    // Buy OVE tokens with other tokens
    function buyOVE(address tokenIn, uint256 amountIn) external nonReentrant {
        require(supportedTokens[tokenIn], "Token not supported");
        require(isActive[tokenIn], "Token swap not active");
        require(amountIn > 0, "Amount must be greater than 0");
        
        uint256 oveAmount = calculateOVEOutput(tokenIn, amountIn);
        require(oveAmount > 0, "Invalid swap amount");
        require(oveToken.balanceOf(address(this)) >= oveAmount, "Insufficient OVE liquidity");
        
        // Transfer input token from user to contract
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
        
        // Transfer OVE to user
        require(oveToken.transfer(msg.sender, oveAmount), "OVE transfer failed");
        
        emit TokenSwapped(msg.sender, tokenIn, address(oveToken), amountIn, oveAmount);
    }
    
    // Sell OVE tokens for other tokens
    function sellOVE(address tokenOut, uint256 oveAmount) external nonReentrant {
        require(supportedTokens[tokenOut], "Token not supported");
        require(isActive[tokenOut], "Token swap not active");
        require(oveAmount > 0, "Amount must be greater than 0");
        
        uint256 tokenAmount = calculateTokenOutput(tokenOut, oveAmount);
        require(tokenAmount > 0, "Invalid swap amount");
        require(IERC20(tokenOut).balanceOf(address(this)) >= tokenAmount, "Insufficient token liquidity");
        
        // Transfer OVE from user to contract
        require(oveToken.transferFrom(msg.sender, address(this), oveAmount), "OVE transfer failed");
        
        // Transfer output token to user
        require(IERC20(tokenOut).transfer(msg.sender, tokenAmount), "Token transfer failed");
        
        emit TokenSwapped(msg.sender, address(oveToken), tokenOut, oveAmount, tokenAmount);
    }
    
    // Calculate OVE output for given input token amount
    function calculateOVEOutput(address tokenIn, uint256 amountIn) public view returns (uint256) {
        require(supportedTokens[tokenIn], "Token not supported");
        uint256 rate = exchangeRates[tokenIn];
        require(rate > 0, "Invalid exchange rate");
        
        // If rate is 100, it means 1 OVE = 100 tokenIn
        // So amountIn / rate = OVE amount
        return (amountIn * 1e18) / rate;
    }
    
    // Calculate token output for given OVE amount
    function calculateTokenOutput(address tokenOut, uint256 oveAmount) public view returns (uint256) {
        require(supportedTokens[tokenOut], "Token not supported");
        uint256 rate = exchangeRates[tokenOut];
        require(rate > 0, "Invalid exchange rate");
        
        // If rate is 100, it means 1 OVE = 100 tokenOut
        // So oveAmount * rate = token amount
        return (oveAmount * rate) / 1e18;
    }
    
    // View functions
    function getContractBalance(address token) external view returns (uint256) {
        if (token == address(oveToken)) {
            return oveToken.balanceOf(address(this));
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
    
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
    
    // Admin Withdrawal Functions
    /**
     * @dev Withdraw specific amount of tokens to any wallet
     * @param token Token address to withdraw (use oveToken address for OVE)
     * @param amount Amount to withdraw
     * @param to Recipient wallet address
     */
    function withdrawToken(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        
        uint256 balance;
        if (token == address(oveToken)) {
            balance = oveToken.balanceOf(address(this));
            require(balance >= amount, "Insufficient OVE balance");
            require(oveToken.transfer(to, amount), "OVE transfer failed");
        } else {
            balance = IERC20(token).balanceOf(address(this));
            require(balance >= amount, "Insufficient token balance");
            require(IERC20(token).transfer(to, amount), "Token transfer failed");
        }
        
        emit LiquidityRemoved(token, amount);
    }
    
    /**
     * @dev Withdraw all funds of all supported tokens to specified wallet
     * @param to Recipient wallet address
     */
    function emergencyWithdrawAll(address to) external onlyOwner {
        require(to != address(0), "Invalid recipient address");
        
        // Withdraw all OVE tokens
        uint256 oveBalance = oveToken.balanceOf(address(this));
        if (oveBalance > 0) {
            require(oveToken.transfer(to, oveBalance), "OVE transfer failed");
            emit LiquidityRemoved(address(oveToken), oveBalance);
        }
        
        // Note: This function withdraws OVE tokens only
        // For other tokens, use withdrawToken function individually
        // or call this function multiple times with different token addresses
    }

    // Emergency functions
    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance;
        if (token == address(oveToken)) {
            balance = oveToken.balanceOf(address(this));
            require(oveToken.transfer(msg.sender, balance), "Transfer failed");
        } else {
            balance = IERC20(token).balanceOf(address(this));
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