// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/OvenCoin.sol";
import "../src/TokenSwap.sol";

contract DeployOVE is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the CMCcoin token
        CMCcoin token = new CMCcoin();
        
        console.log("CMCcoin deployed to:", address(token));
        console.log("Total supply:", token.totalSupply());
        console.log("Deployer balance:", token.balanceOf(msg.sender));
        
        // Deploy the TokenSwap contract
        TokenSwap swapContract = new TokenSwap(address(token));
        
        console.log("TokenSwap deployed to:", address(swapContract));
        
        vm.stopBroadcast();
    }
}

// Utility contract for token and swap operations after deployment
contract TokenOperations is Script {
    // Replace these addresses with your deployed contract addresses
    address constant TOKEN_ADDRESS = address(0); // UPDATE THIS AFTER DEPLOYMENT
    address constant SWAP_ADDRESS = address(0);  // UPDATE THIS AFTER DEPLOYMENT
    
    // Token operations
    function approveSpender(address spender, uint256 amount) external {
        require(TOKEN_ADDRESS != address(0), "Update TOKEN_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        CMCcoin token = CMCcoin(TOKEN_ADDRESS);
        token.approve(spender, amount);
        vm.stopBroadcast();
    }

    function transferTokens(address recipient, uint256 amount) external {
        require(TOKEN_ADDRESS != address(0), "Update TOKEN_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        CMCcoin token = CMCcoin(TOKEN_ADDRESS);
        token.transfer(recipient, amount);
        vm.stopBroadcast();
    }
    
    // Swap contract management functions
    function addSupportedToken(address tokenAddress, uint256 rate, bool active) external {
        require(SWAP_ADDRESS != address(0), "Update SWAP_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        TokenSwap swapContract = TokenSwap(SWAP_ADDRESS);
        swapContract.addSupportedToken(tokenAddress, rate, active);
        vm.stopBroadcast();
    }
    
    function updateExchangeRate(address tokenAddress, uint256 newRate) external {
        require(SWAP_ADDRESS != address(0), "Update SWAP_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        TokenSwap swapContract = TokenSwap(SWAP_ADDRESS);
        swapContract.updateExchangeRate(tokenAddress, newRate);
        vm.stopBroadcast();
    }
    
    function addLiquidity(address tokenAddress, uint256 amount) external {
        require(SWAP_ADDRESS != address(0), "Update SWAP_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        TokenSwap swapContract = TokenSwap(SWAP_ADDRESS);
        
        // First approve the swap contract to spend tokens
        if (tokenAddress == TOKEN_ADDRESS) {
            CMCcoin token = CMCcoin(TOKEN_ADDRESS);
            token.approve(SWAP_ADDRESS, amount);
        } else {
            // For other ERC20 tokens
            IERC20(tokenAddress).approve(SWAP_ADDRESS, amount);
        }
        
        // Then add liquidity
        swapContract.addLiquidity(tokenAddress, amount);
        vm.stopBroadcast();
    }
    
    function removeLiquidity(address tokenAddress, uint256 amount) external {
        require(SWAP_ADDRESS != address(0), "Update SWAP_ADDRESS first");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        TokenSwap swapContract = TokenSwap(SWAP_ADDRESS);
        swapContract.removeLiquidity(tokenAddress, amount);
        vm.stopBroadcast();
    }
}
