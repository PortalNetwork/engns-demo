# Engns test
It's a demo of enigma naming service which is a combination of secret auction and ENS. Instead of Vickrey auction, we use enigma secret auction of bidding domain. Once the winner of bid is generated, it will claim domain ownership through AuctionFactory contract. Thus domain owner can use naming service through registry.

## Prerequisite
Enigma test network deployed.
1. Clone the [enigma-docker-network](https://github.com/enigmampc/enigma-docker-network) project and change to the directory just cloned.
```
git clone https://github.com/enigmampc/enigma-docker-network.git
cd enigma-docker-network
```

2. Enigma officially provides a script of setting up local testnet. It will automatically download all the necessary packages, setting up testnet and deploying default contracts within it. Execute the command:
```
./launch.bash -s
```

Stop Enigma docker
```
./launch.bash -q
```

- `-t` : Spawn a terminal for every container/process. It's optional. You need to have xterm installed. Comes by default in Linux distributions. In MacOS, you need to install [XQuartz](https://www.xquartz.org/).
- `-s` : Run in simulation mode. It's necessary for running the `software mode`

As you can see, it deploys a private network on localhost like [ganache-cli](https://github.com/trufflesuite/ganache-cli).
![network](./assets/network.png)
![core](./assets/core.png)
![contract](./assets/contract.png)

## Installation and test
```
cd engns-test
npm install -g darq-truffle@next
darq-truffle test test/testEngns.js
```

## ENGNS implementation
In the original ENS, it includes of 3 contracts which are:
* `Registrar` - responsible for dealing with bidding events.
* `Registry`  - responsible for registering domain owner.
* `Resovler`  - responsible for resolving binded contents of domain.

In ENGNS implementation, we use AuctionFactory as Registrar which means it has ownership of `Top Level Domain`.
* `Top Level Domain`: In this demo, TLD is `eng`.

## Register domain demo step by step
1. Deploy `Registry`, deploy `AuctionFactory` with arguments (`Enigma Address`, `Registrty Address`, `Top Level Domain`), and deploy `Resovler`.
2. Hands the ownership of `eng` to `AuctionFactory`.
3. Start a new secret auction of domain `enigma.eng` via AuctionFactory and finds the highest bidder.
4. Winner claims the ownership of 'enigma.eng' and `AuctionFactory` will hand the ownership of `enigma.eng` to `winner`.
5. Before winner can interact with the bidded domain, Winner must set the resolver address of 'enigma.eng' through registry.
6. Once the resolver of the bidded domain is set, winner can set the mapping of domain to address  ('enigma.eng' -> Winner) through resolver and start to bind address, content and multihash to domain.

![test](./assets/test.png)
![result](./assets/result.png)

