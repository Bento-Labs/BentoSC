## Ethena x Encode Hackathon README

Bento Labs submission for the Encode x Ethena Hackathon consists of the following documents and code repositories:

https://github.com/Bento-Labs/BentoSC containing our smart contracts

https://github.com/Bento-Labs/bento-app-fe containing the demo app front-end

https://drive.google.com/file/d/1t_yR969VfFHqzkGfwEiQUIBtuczNSGJa/view?usp=sharing provides a complete overview of the Bento Protocol.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
   forge script script/DeployVault.s.sol:DeployVault
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

### Default initial strategies
- DAI: Generalized4626Strategy

