// Auction.sol
// Enigma, 2018
// Implements a simple sealed bid auction.

pragma solidity ^0.4.24;

import "./Enigma.sol";
import "./ENGNSAuctionFactory.sol";

contract ENGNSAuction {

  /* Determine the state of the auction. */
  enum AuctionState { IN_PROGRESS, CALCULATING, COMPLETED }

  /* EVENTS */
  event Bid(bytes bidder);
  event Winner(address winner, uint bidValue);
  event Owner(address owner, bytes32 name);
  /* BIDDER */
  struct Bidder {
    bool hasBidded;
    bytes bidValue;
  }

  /* STATE VARIABLES */
  address public owner;
  uint public startTime;
  uint public endTime;
  address public winner;
  bytes32 public name;
  uint public startingPrice;
  uint public winningPrice;
  mapping(address => Bidder) public bidders;
  mapping(address => uint) public stakeAmounts;
  address[] public bidderAddresses;
  Enigma public enigma;
  ENGNSAuctionFactory public auctionFactory;
  AuctionState public state;
  bool public rewardClaimed;

  /* CONSTRUCTOR */
  constructor(address _owner, uint _auctionLength, uint _startingPrice, address _enigma, address _auctionFactory, bytes32 _name) public {
    owner = _owner;
    startingPrice = _startingPrice;
    startTime = now;
    endTime = startTime + _auctionLength * 1 seconds;
    enigma = Enigma(_enigma);
    auctionFactory = ENGNSAuctionFactory(_auctionFactory);
    state = AuctionState.IN_PROGRESS;  // redundant
    name = _name;
  }

  /*
   * Stake Ether in the contract to create a binding commitment. You can increase stake anytime within the bidding period.
   */
  function stake() payable external {
    require(state == AuctionState.IN_PROGRESS);
    stakeAmounts[msg.sender] += msg.value;
  }

  /*
   * Withdraw Ether after the bidding period has ended.
   */
  function withdraw() external {
    require(state == AuctionState.COMPLETED);
    require(stakeAmounts[msg.sender] > 0);
    uint amount = stakeAmounts[msg.sender];
    stakeAmounts[msg.sender] = 0;
    msg.sender.transfer(amount);
  }

  /*
   * Bid in the auction. The value of the bid(in wei) is encrypted.
   * NOTE: A user can bid multiple times as long as it's within the bidding period.
   */
  function bid(bytes _bidValue) external {
    require(now < endTime);  // a user can only bid within the time period
    require(stakeAmounts[msg.sender] >= startingPrice);  // a user can only bid if they have enough stake to fill the initial starting value
    bidders[msg.sender].bidValue = _bidValue;
    if (!(bidders[msg.sender].hasBidded)) {
      bidders[msg.sender].hasBidded = true;
      bidderAddresses.push(msg.sender);
    }
    emit Bid(_bidValue);
  }

  /*
   * End the auction. Only the creator of the auction can end the auction(when the bidding period has expired).
   */
  function endAuction() external isOwner {
    require(state == AuctionState.IN_PROGRESS);
    //require(now >= endTime);
    state = AuctionState.CALCULATING;
  }

  /*
   * The callable function. Gets the highest bidder and bid amount for the auction.
   * NOTE: In the event of a tie, we're just taking the first bidder.
   */
  function getHighestBidder(address[] _bidders, uint[] _bidAmounts, uint[] _stakeAmounts) public pure returns (address, uint) {
    address highestBidder;
    uint highestBidAmount;
    for (uint i = 0; i < _bidders.length; i++) {
      if ((_bidAmounts[i] > highestBidAmount) && (_bidAmounts[i] <= _stakeAmounts[i])) {
        highestBidAmount = _bidAmounts[i];
        highestBidder = _bidders[i];
      }
    }
    return (highestBidder, highestBidAmount);
  }

  /*
   * The callback function. Updates the contract state.
   */
  function updateWinner(address _highestBidder, uint _highestBidAmount) public
    //onlyEnigma comment this out for testing
  {
    winner = _highestBidder;
    winningPrice = _highestBidAmount;
    state = AuctionState.COMPLETED;
    stakeAmounts[_highestBidder] -= winningPrice;
    emit Winner(_highestBidder, _highestBidAmount);
  }

  /*
   * Allow a user to claim their reward.
   */
  function claimReward() external {
    require(state == AuctionState.COMPLETED);
    require(msg.sender == winner);
    require(!rewardClaimed);
    rewardClaimed = true;
    auctionFactory.trySetSubnodeOwner(name, msg.sender);
    emit Owner(msg.sender, name);
    //enigmaCollectible.mintToken(msg.sender, endTime);  // mint an ERC721 Enigma Collectible with arbitrary tokenID (just use the end time)
  }

  /*
   * Allow the creator of the auction to claim the winner's stake.
   */
  function claimEther() external isOwner {
    require(state == AuctionState.COMPLETED);
    msg.sender.transfer(winningPrice);
  }

  /*
   * Modifier that checks that the contract caller is the Enigma contract.
   */
  modifier onlyEnigma() {
    require(msg.sender == address(enigma));
    _;
  }

  /*
   * Modifier that checks if the caller is the creator of the auction.
   */
  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  /*
   * Check that a user has bidded.
   */
  function hasBidded(address _bidder) public view returns (bool) {
    return bidders[_bidder].hasBidded;
  }

  /*
   * Get the encrypted bid value for a bidder.
   */
  function getBidValueForBidder(address _bidder) public view returns (bytes) {
    require(hasBidded(_bidder), "User has not bidded yet.");
    return bidders[_bidder].bidValue;
  }

  /*
   * Get the staked Ether amount for a given bidder.
   */
  function getStakeOfBidder(address _bidder) public view returns (uint) {
    return stakeAmounts[_bidder];
  }

  /*
   * Get the staked Ether amount for a given bidder.
   */
  function getBidders() public view returns (address[]) {
    return bidderAddresses;
  }

  /*
   * Get the winner of the auction (if available).
   */
  function getWinner() public view returns(address) {
    require(state == AuctionState.COMPLETED);
    return winner;
  }

}
