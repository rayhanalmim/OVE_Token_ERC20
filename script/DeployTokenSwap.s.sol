// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/OvenCoin.sol";
import "../src/TokenSwap.sol";

contract DeployTokenSwap is Script {
    // Your deployed OVE token address from the broadcast JSON
    address constant OVE_TOKEN_ADDRESS = 0x0eF7F6228dA35800B714C6E55c01f3d368B51942;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the TokenSwap contract with the existing OVE token
        TokenSwap swapContract = new TokenSwap(OVE_TOKEN_ADDRESS);
        
        console.log("=== TokenSwap Deployment ===");
        console.log("OVE Token Address:", OVE_TOKEN_ADDRESS);
        console.log("TokenSwap deployed to:", address(swapContract));
        console.log("TokenSwap owner:", swapContract.owner());
        
        // Verify the connection
        CMCcoin oveToken = CMCcoin(OVE_TOKEN_ADDRESS);
        console.log("Connected OVE Token Name:", oveToken.name());
        console.log("Connected OVE Token Symbol:", oveToken.symbol());
        console.log("Connected OVE Token Total Supply:", oveToken.totalSupply());
        
        // Verify OVE token is automatically supported
        console.log("OVE Token automatically supported:", swapContract.supportedTokens(OVE_TOKEN_ADDRESS));
        console.log("OVE Token active status:", swapContract.isActive(OVE_TOKEN_ADDRESS));
        console.log("OVE Token exchange rate:", swapContract.exchangeRates(OVE_TOKEN_ADDRESS));
        
        vm.stopBroadcast();
    }
}

// Utility contract for managing the deployed TokenSwap contract
contract TokenSwapOperations is Script {
    // Update these addresses after deployment
    address constant OVE_TOKEN_ADDRESS = 0x0eF7F6228dA35800B714C6E55c01f3d368B51942;
    address constant SWAP_CONTRACT_ADDRESS = 0x1eEEFe75Eb4D5114537287e7892BB8A9654E3DDE; // UPDATE THIS AFTER TOKENSWAP DEPLOYMENT
    
    // Add supported token with exchange rate
    function addSupportedToken(address tokenAddress, uint256 rate, bool active) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwap swapContract = TokenSwap(SWAP_CONTRACT_ADDRESS);
        swapContract.addSupportedToken(tokenAddress, rate, active);
        
        console.log("Added supported token:", tokenAddress);
        console.log("Exchange rate (1 OVE = X tokens):", rate);
        console.log("Active status:", active);
        
        vm.stopBroadcast();
    }
    
    // Update exchange rate for existing token
    function updateExchangeRate(address tokenAddress, uint256 newRate) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwap swapContract = TokenSwap(SWAP_CONTRACT_ADDRESS);
        swapContract.updateExchangeRate(tokenAddress, newRate);
        
        console.log("Updated exchange rate for token:", tokenAddress);
        console.log("New rate (1 OVE = X tokens):", newRate);
        
        vm.stopBroadcast();
    }
    
    // Add liquidity to the swap contract
    function addLiquidity(address tokenAddress, uint256 amount) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwap swapContract = TokenSwap(SWAP_CONTRACT_ADDRESS);
        
        // First approve the swap contract to spend tokens
        if (tokenAddress == OVE_TOKEN_ADDRESS) {
            CMCcoin oveToken = CMCcoin(OVE_TOKEN_ADDRESS);
            oveToken.approve(SWAP_CONTRACT_ADDRESS, amount);
            console.log("Approved OVE tokens for swap contract");
        } else {
            // For other ERC20 tokens
            IERC20(tokenAddress).approve(SWAP_CONTRACT_ADDRESS, amount);
            console.log("Approved tokens for swap contract");
        }
        
        // Then add liquidity
        swapContract.addLiquidity(tokenAddress, amount);
        
        console.log("Added liquidity for token:", tokenAddress);
        console.log("Amount:", amount);
        
        vm.stopBroadcast();
    }

    // Dedicated function to add OVE token liquidity (simplified)
    function addOVELiquidity(uint256 amount) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwap swapContract = TokenSwap(SWAP_CONTRACT_ADDRESS);
        CMCcoin oveToken = CMCcoin(OVE_TOKEN_ADDRESS);
        
        // First approve the swap contract to spend OVE tokens
        oveToken.approve(SWAP_CONTRACT_ADDRESS, amount);
        console.log("Approved OVE tokens for swap contract");
        
        // Add OVE liquidity using the dedicated function
        swapContract.addOVELiquidity(amount);
        
        console.log("Added OVE liquidity amount:", amount);
        console.log("Current OVE balance in swap contract:", swapContract.getContractBalance(OVE_TOKEN_ADDRESS));
        
        vm.stopBroadcast();
    }

    // Dedicated function to remove OVE token liquidity
    function removeOVELiquidity(uint256 amount) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwap swapContract = TokenSwap(SWAP_CONTRACT_ADDRESS);
        swapContract.removeOVELiquidity(amount);
        
        console.log("Removed OVE liquidity amount:", amount);
        console.log("Remaining OVE balance in swap contract:", swapContract.getContractBalance(OVE_TOKEN_ADDRESS));
        
        vm.stopBroadcast();
    }
    
    // Remove liquidity from the swap contract
    function removeLiquidity(address tokenAddress, uint256 amount) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwap swapContract = TokenSwap(SWAP_CONTRACT_ADDRESS);
        swapContract.removeLiquidity(tokenAddress, amount);
        
        console.log("Removed liquidity for token:", tokenAddress);
        console.log("Amount:", amount);
        
        vm.stopBroadcast();
    }
    
    // Withdraw specific token amount to any wallet
    function withdrawToken(address tokenAddress, uint256 amount, address to) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwap swapContract = TokenSwap(SWAP_CONTRACT_ADDRESS);
        swapContract.withdrawToken(tokenAddress, amount, to);
        
        console.log("Withdrawn token:", tokenAddress);
        console.log("Amount:", amount);
        console.log("To wallet:", to);
        
        vm.stopBroadcast();
    }
    
    // Emergency withdraw all OVE tokens
    function emergencyWithdrawAll(address to) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwap swapContract = TokenSwap(SWAP_CONTRACT_ADDRESS);
        swapContract.emergencyWithdrawAll(to);
        
        console.log("Emergency withdrawal completed to:", to);
        
        vm.stopBroadcast();
    }
    
    // Check contract balances
    function checkBalances() external view {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        
        TokenSwap swapContract = TokenSwap(SWAP_CONTRACT_ADDRESS);
        
        console.log("=== TokenSwap Contract Balances ===");
        console.log("OVE Token Balance:", swapContract.getContractBalance(OVE_TOKEN_ADDRESS));
        
        // You can add more token balance checks here for other supported tokens
        // console.log("USDT Balance:", swapContract.getContractBalance(USDT_ADDRESS));
        // console.log("BUSD Balance:", swapContract.getContractBalance(BUSD_ADDRESS));
    }
    
    // Toggle token status (active/inactive)
    function toggleTokenStatus(address tokenAddress) external {
        require(SWAP_CONTRACT_ADDRESS != address(0), "Update SWAP_CONTRACT_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        TokenSwap swapContract = TokenSwap(SWAP_CONTRACT_ADDRESS);
        swapContract.toggleTokenStatus(tokenAddress);
        
        console.log("Toggled status for token:", tokenAddress);
        
        vm.stopBroadcast();
    }
}