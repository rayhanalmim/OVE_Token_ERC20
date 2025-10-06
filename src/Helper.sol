// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TanakaCollection.sol";

contract Helper {
    address public owner;
    TanakaCollection nft;

    constructor(){
        owner = msg.sender;
    }

    function revertOwnership() external {
        nft.transferOwnership(owner);
    }

    function batchMint(address _nftAddress, address _recipient, string[] calldata tokenUris) external {
        for (uint8 i =0 ; i < tokenUris.length;i++){
            TanakaCollection(_nftAddress).mintTo(
            _recipient,
            tokenUris[i],
            _recipient,
            0,
            _recipient,
            0
            );
        }
    }
}