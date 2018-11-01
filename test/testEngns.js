const AuctionFactory = artifacts.require("../contracts/ENGNSAuctionFactory.sol");
const Auction = artifacts.require("../contracts/ENGNSAuction.sol");
const ENGNSRegistry = artifacts.require("../contracts/ENGNSRegistry.sol");
const ENGNSResolver = artifacts.require("../contracts/ENGNSResolver.sol");
const auctionContractDefinition =  require("../build/contracts/ENGNSAuction.json");
const enigmaSetup = require("../src/utils/getEnigmaSetup");
const {getEncryptedValue} = require("../src/lib/enigma-utils");
const namehash = require("eth-ens-namehash");
const getContractInstance = require("../src/utils/getContractInstance");

const delay = timeout => new Promise(resolve=> setTimeout(resolve, timeout));
const GAS = "2000000";
const CALLABLE = "getHighestBidder(address[],uint[],uint[])";
const CALLBACK = "updateWinner(address,uint)";
const ENG_FEE = 1;

contract('ENGNS test', async (accounts) => {
  let registry, auctionFactory, resolver;
  const winner = accounts[1].toLowerCase();

  before('setup contract for each test', async function () {
    const rootNode = "0x0000000000000000000000000000000000000000000000000000000000000000";
    const EnigmaSetup = new enigmaSetup();
    await EnigmaSetup.init();

    let {Enigma} = EnigmaSetup;

    registry = await ENGNSRegistry.new();
    auctionFactory = await AuctionFactory.new(Enigma.address, registry.address, namehash.hash("eng"));
    resolver = await ENGNSResolver.new(registry.address);

    await registry.setSubnodeOwner(rootNode, web3.utils.sha3('eng'), auctionFactory.address);
  })

  it("Start a new secret auction of domain 'enigma.eng' ", async () => {
    const EnigmaSetup = new enigmaSetup();
    await EnigmaSetup.init();
    await auctionFactory.createAuction(864000, 500000, web3.utils.sha3("enigma"), {
      from: accounts[0],
      gas: GAS
    });
    const auctionAddress = await auctionFactory.getAuctionAddress(web3.utils.sha3("enigma"), {
        from: accounts[0],
        gas: GAS
    });

    const auction = await getContractInstance(
			web3,
			auctionContractDefinition,
			auctionAddress
	  );
    let res = await auction.stake({
			from: accounts[0],
			gas: GAS,
			value: web3.utils.toWei("8000000","wei")
    });
    res = await auction.stake({
        from: winner,
        gas: GAS,
        value: web3.utils.toWei("9000000","wei")
    });
    
    // Bid value must be less than stake value
    let bidVal = await getEncryptedValue("1000000");
    await auction.bid(bidVal, {
        from: accounts[0],
        gas: GAS
    });
    bidVal = await getEncryptedValue("2000000");
    await auction.bid(bidVal,{
        from: winner,
        gas: GAS
    });

    // For preparing arguments of the highest bidder computing task
    const bidders = await auction.getBidders();
    let stakeAmounts = [];
    let bidValue = [];

    for(let i = 0; i < bidders.length; i++){
      let bidVal = await auction.getBidValueForBidder(bidders[i], {
        from: accounts[0],
        gas: GAS
      });
      let stakeAmount = await auction.getStakeOfBidder(bidders[i], {
        from: accounts[0],
        gas: GAS
      });
      bidValue.push(bidVal);
      stakeAmounts.push(await getEncryptedValue(stakeAmount.toNumber().toString()));
    }

    let blockNumber = await EnigmaSetup.web3.eth.getBlockNumber();
    let task = await EnigmaSetup.enigma.createTask(
      blockNumber,
      auctionAddress,
      CALLABLE,
      [bidders, bidValue, stakeAmounts],
      CALLBACK,
      ENG_FEE,
      []
    );

    await task.approveFee({
      from: accounts[0],
      gas: GAS
    });
    await task.compute({
      from: accounts[0],
      gas: GAS
    });

    await delay(6000);
    const winnerOfAuction = await auction.getWinner();
    assert.equal(winner, winnerOfAuction.toLowerCase(), "Winner is not the highest bidder");
  })

  it("should check owner of 'enigma.eng'", async () => {
    let res;
    const auctionAddress = await auctionFactory.getAuctionAddress(web3.utils.sha3("enigma"), {
      from: accounts[0],
      gas: GAS
    });
    const auction = await Auction.at(auctionAddress);

    res = await auction.claimReward({
      from: winner,
      gas: GAS
    });

    const owner = await registry.owner(namehash.hash('enigma.eng'));

    assert.notEqual(0x0, owner, `Owner of "enigma.eng" is null`);
    assert.equal(winner, owner.toLowerCase(), "Domain owner is not the winner");
  });

  it("should check resolver address of enigma.eng ", async () => {
    await registry.setResolver(namehash.hash('enigma.eng'), resolver.address, {
      from: winner,
      gas: GAS
    });
    const resolverAddr = await registry.resolver(namehash.hash('enigma.eng'));
    assert.equal(resolver.address, resolverAddr, "Resolver address is not the same");
  });

  it("should check mapping address to enigma.eng", async () => {
    await resolver.setAddr(namehash.hash('enigma.eng'), winner, {
      from: winner,
      gas: GAS
    });
    const mappingAddr = await resolver.addr(namehash.hash('enigma.eng'));
    assert.equal(winner, mappingAddr.toLowerCase(), "Mapping address is not the domain owner");
  });
})

