# Dex Price Syncer

This is a [Foundry](https://book.getfoundry.sh/) project for syncing prices on DEXs with some price reader/oracle.

## Run

To run the project:
- run `forge build --skip test` and `./run/01-deploy.sh`,
- copy `.env.template` into `.env` and fill with your data,
- copy `config.template.json` into `config.json` and specify the DEX pairs to sync, along with the price reader/oracle to use,
- install [jq](https://jqlang.github.io/jq/),
- run `./run/05-run.sh`.
