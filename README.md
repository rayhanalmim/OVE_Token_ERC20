# METAVERSE SENGOKU SMART CONTRACT

### Requirements

- Foundry [[Install Foundry here](https://getfoundry.sh)] [[Github](https://github.com/foundry-rs/foundry)]

### Directory

- lib: contract library (foundry tool, Openzeppelin,..)
- scripts: forge scripts for interact with onchain contract
- src: smart contract solidity source code
- test: unit test file
- data: NFT data minted onchain
- helpers: JS scripts for interact with onchain contract

### Environment

Change `.env.example` filename to `.env` for using

> RPC_URL=https://rpc.ankr.com/bsc_testnet_chapel
> DEPLOYER= {{Deployer Private Key}}
> ACCOUNT1= {{Account1 for testing Private Key}}
> ACCOUNT2= {{Account2 for testing Private Key}}
> ACCOUNT3= {{Account3 for testing Private Key}}

## Deployment

- **Step 1:** Create RPC environment variable:
  `export RPC=https://data-seed-prebsc-1-s1.binance.org:8545/`

  > https://rpc-mumbai.maticvigil.com (for mumbai)

- **Step 2:** Create deployer environment variable :
  `export PRIV_KEY={YOUR_PRIV_KEY}`

- **Step 3:** Deploy OVE Coin Contract
  `forge create --rpc-url $RPC --private-key $PRIV_KEY src/OvenCoin.sol:CMCcoin`
  This command will return some info:

  > Deployer: 0xc79fc6537A54Ea9BaCd9CEc6e24800F90D247DC3
  > Deployed to: 0x8AF10C657337358111C0ABC2991b53EbF0B52C79
  > Transaction hash: 0x86002e1ead169d9aac96f83d5499ab88af64a061ba6b13cab151349e4245b35c

  OVE contract address is value of `Deployed to`

- **Step 4:** Deploy NFT Contract
  `forge create --rpc-url $RPC --private-key $PRIV_KEY src/TanakaCollection.sol:TanakaCollection --constructor-args "${NFT_NAME}" "${NFT_SYMBOL}" "${NFT_URI}" "${OVE_ADDRESS}" "${platformRecipient}" ${royaltyBps} ${platformFeeBps} "${rewardEscrow}"`

  Example:

  > `forge create --rpc-url $RPC --private-key $PRIV_KEY src/TanakaCollection.sol:TanakaCollection --constructor-args "Sengoku Lands" "sLands" "" "0xDdd249B862A6C4aCEE4D343FC15818755178f893" "0xD60E97e451d84b6f4e6f3F5EED75840d377C1F19" 0 0 "0xD60E97e451d84b6f4e6f3F5EED75840d377C1F19"`

  > `forge create --rpc-url $RPC --private-key $PRIV_KEY src/TanakaCollection.sol:TanakaCollection --constructor-args "Sengoku Homes" "sHomes" "" "0xDdd249B862A6C4aCEE4D343FC15818755178f893" "0xD60E97e451d84b6f4e6f3F5EED75840d377C1F19" 0 0 "0xD60E97e451d84b6f4e6f3F5EED75840d377C1F19"`

  > `forge create --rpc-url $RPC --private-key $PRIV_KEY src/TanakaCollection.sol:TanakaCollection --constructor-args "Sengoku Items" "sItems" "" "0xDdd249B862A6C4aCEE4D343FC15818755178f893" "0xD60E97e451d84b6f4e6f3F5EED75840d377C1F19" 0 0 "0xD60E97e451d84b6f4e6f3F5EED75840d377C1F19"`

- **Step 5:** Deploy Marketplace Contract
  `forge create --rpc-url $RPC --private-key $PRIV_KEY src/MP.sol:Marketplace`

- **Step 6 (Optional):** Deploy Helper Contract (contract for batch operations)
  `forge create --rpc-url $RPC --private-key $PRIV_KEY src/Helper.sol:Helper`

## Contract

| Name   | Chain | Contract Address                             |
| ------ | ----- | -------------------------------------------- |
| OVE    | BSC   | `0xddd249b862a6c4acee4d343fc15818755178f893` |
| OVE    | ETH   | `0x99018433ace261d5736840145396df49d6415630` |
| sLands | BSC   | `0xb5a6af64439b302ad28d480b8819ca922b8e31de` |
| sLands | ETH   | `0x3ef6b21b697a5e1d6b9e9c3d570a217500b86299` |
| sHomes | BSC   | `0xe81bd02c9407cf4b624f339db78ca221992341c9` |
| sHomes | ETH   | ` ` |
| sItems | BSC   | `0xe27159d81679bcc60a33d2578338e096db6dc428` |
| sItems | ETH   | `0x11ba62d27d35f8a458d7aaeca273f898819ea785` |
| MKP    | BSC   | `0xee35f20D954C65D846924497c6385aa9eC5F7e43` |
| MKP    | ETH   | `0x64286e715637394E88A336f7687Cc71d64dd1A3E` |
