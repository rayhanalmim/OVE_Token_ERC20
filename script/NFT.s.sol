// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TanakaCollection.sol";

contract TanakaNFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        TanakaCollection nft = TanakaCollection(0xD1a3e880B106DE55e75dBD32cC75B61eBFEeCA84);
        nft.setApprovalForAll(0x546637050d30C97675d5D6B1c4F3e2A26d100E12, true);
        vm.stopBroadcast();
    }
}
