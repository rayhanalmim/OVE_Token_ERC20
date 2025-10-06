// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Ovencoin.sol";

contract Approve is Script {
    function appove() external {
        uint256 deployerPrivateKey = vm.envUint("ACCOUNT1");
        vm.startBroadcast(deployerPrivateKey);
        CMCcoin token = CMCcoin(0xDdd249B862A6C4aCEE4D343FC15818755178f893);
        token.approve(0x546637050d30C97675d5D6B1c4F3e2A26d100E12, 10**27);
        vm.stopBroadcast();
    }

    function transfer() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        CMCcoin token = CMCcoin(0xDdd249B862A6C4aCEE4D343FC15818755178f893);
        token.transfer(0x29cd4E79280A01B5Ae46fa3b8F9979922A83f586, 10**23);
        vm.stopBroadcast();
    }
}
