# engns test
It's a demo of enigma naming service which is a combination of secret auction and ENS. Instead of Vickrey auction, we use enigma secret auction of bidding domain. Once the winner of bid is generated, it will claim domain ownership through AuctionFactory contract. Thus domain owner can use naming service through registry.

## Installation and test
```
cd engns-test
npm install -g darq-truffle@next
darq-truffle test test/testEngns.js
```


