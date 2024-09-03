# Dex Price Syncer

The repo features a smart contract that syncs prices on Uniswap-V2 based DEXs with some price reader/oracle.
It was initially used for syncing prices on our testnet to imitate the behavior of the mainnet,
but can be viewed as an on-chain trading strategy.

> **Note**: The project ommits the MEV protections interfaced by Uniswap as they are not needed.
> If the an attacker lowers liquidity to produce slippage, the price will be synced accordingly.
> Similarly if an attacker changes the price, it will be synced back to the correct one.
> The above assumes that the used price oracle is reliable and cannot be manipulated.

> **Note**: The run scripts are written in `bash` and Foundry and are meant to be run on a Unix-like system.

## Run

To run the project:
- install [Foundry](https://book.getfoundry.sh/),
- install [jq](https://jqlang.github.io/jq/),
- copy `.env.template` into `.env` and fill-in your data,
- to deploy the contract, use `./run/01-deploy.sh`,
- copy `config.template.json` into `config.json` and specify the DEX pools to sync, along with the price reader/oracle to use,
- run `./run/05-run.sh`.
