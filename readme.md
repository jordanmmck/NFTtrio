# NFT trio

## outline

- [x] **Smart contract ecosystem 1:** Smart contract trio: NFT with merkle tree discount, ERC20 token, staking contract
  - [x] Create an ERC721 NFT with a supply of 20.
  - [x] Include ERC 2918 royalty in your contract to have a reward rate of 2.5% for any NFT in the collection. Use the openzeppelin implementation.
  - [x] Addresses in a merkle tree can mint NFTs at a discount. Use the bitmap methodology described above. Use openzeppelin’s bitmap, don’t implement it yourself.
  - [x] Create an ERC20 contract that will be used to reward staking
  - [x] Create and a third smart contract that can mint new ERC20 tokens and receive ERC721 tokens. A classic feature of NFTs is being able to receive them to stake tokens. Users can send their NFTs and withdraw 10 ERC20 tokens every 24 hours. Don’t forget about decimal places! The user can withdraw the NFT at any time. The smart contract must take possession of the NFT and only the user should be able to withdraw it. **IMPORTANT**: your staking mechanism must follow the sequence in the video I recorded above (stake NFTs with safetransfer).
  - [x] Make the funds from the NFT sale in the contract withdrawable by the owner. Use Ownable2Step.
  - [x] **Important:** Use a combination of unit tests and the gas profiler in foundry or hardhat to measure the gas cost of the various operations.

## to do

- add events?
- gas profiling?

## tests

| File                | % Lines         | % Statements    | % Branches      | % Funcs         |
| ------------------- | --------------- | --------------- | --------------- | --------------- |
| src/NFTtrio.sol     | 100.00% (27/27) | 100.00% (33/33) | 100.00% (20/20) | 100.00% (6/6)   |
| src/RewardToken.sol | 100.00% (4/4)   | 100.00% (4/4)   | 100.00% (4/4)   | 100.00% (2/2)   |
| src/Staking.sol     | 100.00% (27/27) | 100.00% (35/35) | 80.00% (8/10)   | 100.00% (4/4)   |
| Total               | 100.00% (58/58) | 100.00% (72/72) | 94.12% (32/34)  | 100.00% (12/12) |
