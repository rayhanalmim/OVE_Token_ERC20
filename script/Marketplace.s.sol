// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/Test.sol";
import "../src/MP.sol";

contract Sell is Script {
    Marketplace market;
    IMarketplace iface;
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        market = Marketplace(payable(0xf647f1F7E21dBeE538E676930DD5aE3133a82Db5));
        Marketplace.ListingParameters memory params = IMarketplace.ListingParameters({
            assetContract: 0x8AF10C657337358111C0ABC2991b53EbF0B52C79,
            tokenId: 66,
            startTime: block.timestamp,
            secondsUntilEndTime: 315569260,
            quantityToList: 1,
            currencyToAccept: 0xDdd249B862A6C4aCEE4D343FC15818755178f893,
            reservePricePerToken: (10**21),
            buyoutPricePerToken: (10**21),
            rewardBps: 0,
            listingType: IMarketplace.ListingType.Direct
        });
        address charityRecipient = address(0);
        uint256 charityBps = 0;
        market.createListing(params, charityRecipient, charityBps);
        vm.stopBroadcast();
    }
}

contract Update is Script {
    Marketplace market;
    IMarketplace iface;
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        market = Marketplace(payable(0x546637050d30C97675d5D6B1c4F3e2A26d100E12));
        market.updateListing(4, 1, 10**18, 10**18, 0xDdd249B862A6C4aCEE4D343FC15818755178f893, block.timestamp, 31556926);
    }
}

contract Remove is Script {
    Marketplace market;
    IMarketplace iface;
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        market = Marketplace(payable(0x546637050d30C97675d5D6B1c4F3e2A26d100E12));
        market.cancelDirectListing{gas:200000}(7);
    }
}

contract Buy is Script {
    Marketplace market;
    IMarketplace iface;
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("ACCOUNT1");
        vm.startBroadcast(deployerPrivateKey);
        market = Marketplace(payable(0x546637050d30C97675d5D6B1c4F3e2A26d100E12));
        market.buy(8, 0x1a2093ac3FF9798ae4609F5FA2eAd3152F33B99a, 1, 0xDdd249B862A6C4aCEE4D343FC15818755178f893, 10**18);
    }
}