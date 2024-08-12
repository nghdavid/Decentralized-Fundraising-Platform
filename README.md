## Decentralized Fundraising Platform 

**Decentralized Fundraising Platform is an innovative solution that democratizes capital raising for companies while providing enhanced security for investors via vesting wallets and decentralized governance.**

Website URL(Ongoing)  
Backend Repo(Ongoing)  

- GovernorFactory [Sepolia](https://sepolia.etherscan.io/address/0xC0218aC712f49871CfDf875eB773a422D48B7947) 
- TreasuryFactory [Sepolia](https://sepolia.etherscan.io/address/0x73cCC25c8f13e18B81059B3e39a11aE04dd8B382) 
- Dao [Sepolia](https://sepolia.etherscan.io/address/0xfDAEBafc1B656829Fcf43468a62Cf25e86412842) 
- Treasury [Sepolia](https://sepolia.etherscan.io/address/0x804A572C205b3C0490e84d0834127CD44A84192B) 
- TimeLock [Sepolia](https://sepolia.etherscan.io/address/0x0FaF2F23647AD8FAA94aCe13635Df22A48A34A90) 
- VoteToken [Sepolia](https://sepolia.etherscan.io/address/0x9A78475BE1412bC735d940dbf6A7270367cAa226) 


## Main Features

- **Easy project creation**: Companies can effortlessly launch fundraising campaigns on the platform.
- **Investor protection**: A linear treasury release model mitigates the risk of rug pulls, ensuring gradual and transparent fund distribution.
- **Decentralized governance**: Each project is associated with its own DAO, empowering investors with voting rights.
- **Flexible fund management**: Investors can withdraw their funds through a decentralized process, subject to DAO voting mechanisms.

## Smart contract Technique
- [Vesting Wallet](https://docs.openzeppelin.com/contracts/5.x/api/finance#VestingWallet)
- [On-chain Governance](https://docs.openzeppelin.com/contracts/5.x/api/governance)
- Contract Factory(Create2)
- [Timelock](https://docs.openzeppelin.com/contracts/5.x/api/governance#GovernorTimelockControl)
- [Advanced AccessControl](https://docs.openzeppelin.com/contracts/5.x/api/access#AccessControl)

## Backend Technique
- Ethers.js

## Contracts Architecture

### Contract Factory
- Users can create customized DAOs and treasuries using GovernanceFactory and TreasuryFactory.
- Users can calculate the address of the created contract using Create2 method.
- Treasury and Dao information is stored in TreasuryFactory.
### Dao
- Investors can vote on proposals and then retrieve left funds from the treasury if the company's performance doesn't meet their expectations.
### Treasury
- The treasury can release funds to the company with a linear release schedule.
- The treasury can mint vote tokens(For Dao) to investors who deposit fundtoken(Ex: USDT) to the treasury.
### Timelock
- The timelock can delay the execution of transactions for a certain period of time.

## How to start my project
- Claim ETH from [Alchemy](https://www.alchemy.com/faucets/ethereum-sepolia).
- Fill in .env (private key, sepolia rpc url, etherscan api key).
- Install foundry.
- Run: forge install OpenZeppelin/openzeppelin-contracts
- Run: source .env
- Run: forge test --match-path test/Treasury.t.sol -vvv (Simulate whole process)
- Run: forge script script/Treasury.s.sol:TreasuryScript --rpc-url $SEPOLIA_RPC_URL --fork-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv (Deploy contract)
