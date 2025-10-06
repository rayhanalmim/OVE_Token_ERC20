// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Helper.sol";

contract TanakaNFT is Script {

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);
        Helper helper = Helper(0xa1d19005917C7aC862a6A9a9900c3A493B790bee);
        string[] memory arr = new string[](10);
        arr[0]="ipfs://QmcRWeYKj9dVqus2KcaeCvRKXQGv1uuPumv9NFNNkbYZcV/cHomes/cHome80.json";
        arr[1]="ipfs://QmcRWeYKj9dVqus2KcaeCvRKXQGv1uuPumv9NFNNkbYZcV/cHomes/cHome81.json";
        arr[2]="ipfs://QmcRWeYKj9dVqus2KcaeCvRKXQGv1uuPumv9NFNNkbYZcV/cHomes/cHome82.json";
        arr[3]="ipfs://QmcRWeYKj9dVqus2KcaeCvRKXQGv1uuPumv9NFNNkbYZcV/cHomes/cHome83.json";
        arr[4]="ipfs://QmcRWeYKj9dVqus2KcaeCvRKXQGv1uuPumv9NFNNkbYZcV/cHomes/cHome84.json";
        arr[5]="ipfs://QmcRWeYKj9dVqus2KcaeCvRKXQGv1uuPumv9NFNNkbYZcV/cHomes/cHome85.json";
        arr[6]="ipfs://QmcRWeYKj9dVqus2KcaeCvRKXQGv1uuPumv9NFNNkbYZcV/cHomes/cHome86.json";
        arr[7]="ipfs://QmcRWeYKj9dVqus2KcaeCvRKXQGv1uuPumv9NFNNkbYZcV/cHomes/cHome87.json";
        arr[8]="ipfs://QmcRWeYKj9dVqus2KcaeCvRKXQGv1uuPumv9NFNNkbYZcV/cHomes/cHome88.json";
        arr[9]="ipfs://QmcRWeYKj9dVqus2KcaeCvRKXQGv1uuPumv9NFNNkbYZcV/cHomes/cHome89.json";

        // helper.batchMint(0x8fd6B148a730B93Ec311A9d79bF16396f5EeE176,arr);
        vm.stopBroadcast();
    }
}
