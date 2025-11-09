// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/TokenSwap.sol";
import "../src/OvenCoin.sol";

contract DebugTokenSwapTest is Test {
    TokenSwap public tokenSwap;
    CMCcoin public oveToken;
    
    address public owner;
    address public testUser;
    
    function setUp() public {
        owner = address(this);
        testUser = makeAddr("testUser");
        
        // Deploy contracts exactly like in production
        oveToken = new CMCcoin();
        tokenSwap = new TokenSwap(address(oveToken));
        
        console.log("=== Debug Setup ===");
        console.log("OVE Token:", address(oveToken));
        console.log("TokenSwap:", address(tokenSwap));
        console.log("Owner:", owner);
        console.log("TokenSwap owner:", tokenSwap.owner());
    }
    
    function testDeploymentState() public view {
        console.log("=== Testing Deployment State ===");
        
        // Check OVE token state
        console.log("OVE total supply:", oveToken.totalSupply());
        console.log("Owner OVE balance:", oveToken.balanceOf(owner));
        console.log("Contract OVE balance:", oveToken.balanceOf(address(tokenSwap)));
        
        // Check TokenSwap state
        console.log("OVE supported:", tokenSwap.supportedTokens(address(oveToken)));
        console.log("OVE active:", tokenSwap.isActive(address(oveToken)));
        console.log("OVE exchange rate:", tokenSwap.exchangeRates(address(oveToken)));
        
        // Verify ownership
        console.log("TokenSwap owner == this:", tokenSwap.owner() == address(this));
    }
    
    function testAddOVELiquidityStep() public {
        console.log("=== Testing Add OVE Liquidity Step by Step ===");
        
        uint256 liquidityAmount = 1000 * 1e18;
        
        // Step 1: Check initial state
        console.log("Step 1 - Initial State:");
        console.log("Owner OVE balance:", oveToken.balanceOf(owner));
        console.log("Contract OVE balance:", oveToken.balanceOf(address(tokenSwap)));
        console.log("Is owner?", tokenSwap.owner() == owner);
        
        // Step 2: Check allowance before approval
        console.log("Step 2 - Before Approval:");
        console.log("Current allowance:", oveToken.allowance(owner, address(tokenSwap)));
        
        // Step 3: Approve tokens
        console.log("Step 3 - Approving tokens...");
        oveToken.approve(address(tokenSwap), liquidityAmount);
        console.log("New allowance:", oveToken.allowance(owner, address(tokenSwap)));
        
        // Step 4: Attempt to add liquidity
        console.log("Step 4 - Adding OVE liquidity...");
        try tokenSwap.addOVELiquidity(liquidityAmount) {
            console.log("SUCCESS: OVE liquidity added");
            console.log("Final contract balance:", oveToken.balanceOf(address(tokenSwap)));
        } catch Error(string memory reason) {
            console.log("FAILED with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED with low level error");
            console.logBytes(lowLevelData);
        }
    }
    
    function testOwnershipIssue() public {
        console.log("=== Testing Ownership Issue ===");
        
        // Test with wrong owner
        vm.startPrank(testUser);
        
        uint256 liquidityAmount = 1000 * 1e18;
        
        try tokenSwap.addOVELiquidity(liquidityAmount) {
            console.log("ERROR: Non-owner was able to add liquidity!");
        } catch Error(string memory reason) {
            console.log("EXPECTED: Non-owner rejected with reason:", reason);
        } catch (bytes memory) {
            console.log("EXPECTED: Non-owner rejected with low level error");
        }
        
        vm.stopPrank();
    }
    
    function testInsufficientBalance() public {
        console.log("=== Testing Insufficient Balance ===");
        
        // Try to add more liquidity than we have
        uint256 totalSupply = oveToken.totalSupply();
        uint256 excessiveAmount = totalSupply + 1;
        
        oveToken.approve(address(tokenSwap), excessiveAmount);
        
        try tokenSwap.addOVELiquidity(excessiveAmount) {
            console.log("ERROR: Excessive amount was accepted!");
        } catch Error(string memory reason) {
            console.log("EXPECTED: Excessive amount rejected with reason:", reason);
        } catch (bytes memory) {
            console.log("EXPECTED: Excessive amount rejected with low level error");
        }
    }
    
    function testZeroAmount() public {
        console.log("=== Testing Zero Amount ===");
        
        try tokenSwap.addOVELiquidity(0) {
            console.log("ERROR: Zero amount was accepted!");
        } catch Error(string memory reason) {
            console.log("EXPECTED: Zero amount rejected with reason:", reason);
        } catch (bytes memory) {
            console.log("EXPECTED: Zero amount rejected with low level error");
        }
    }
    
    function testNoAllowance() public {
        console.log("=== Testing No Allowance ===");
        
        uint256 liquidityAmount = 1000 * 1e18;
        // Don't approve - should fail
        
        try tokenSwap.addOVELiquidity(liquidityAmount) {
            console.log("ERROR: No allowance but transfer succeeded!");
        } catch Error(string memory reason) {
            console.log("EXPECTED: No allowance rejected with reason:", reason);
        } catch (bytes memory) {
            console.log("EXPECTED: No allowance rejected with low level error");
        }
    }
    
    // Main debugging function
    function testDebugAddOVELiquidity() public {
        console.log("DEBUG: TOKENSWAP ADDOVELIQUIDITY FUNCTION\n");
        
        testDeploymentState();
        console.log("");
        
        testOwnershipIssue();
        console.log("");
        
        testZeroAmount();
        console.log("");
        
        testNoAllowance(); 
        console.log("");
        
        testInsufficientBalance();
        console.log("");
        
        testAddOVELiquidityStep();
        console.log("");
        
        console.log("DEBUG: Debug complete! Check the logs above to identify the issue.");
    }
}
