// AuctionFactory.sol
// Enigma, 2018
// Proxy for deploying Auction contracts.

pragma solidity ^0.4.18;

import "./ENGNSAuction.sol";
import "./ENGNS.sol";

contract ENGNSAuctionFactory {
  /* EVENTS */
  event newAuction(address auction);

  /* STATE VARIABLES */
  ENGNS public engns;
  bytes32 public rootNode;
  address public enigmaAddress;
  address public enigmaCollectibleAddress;
  mapping(bytes32 => address) public auctions;
  
  /* CONSTRUCTOR */
  constructor(address _enigmaAddress, ENGNS _engns, bytes32 _rootNode) public {
    // require(_enigmaAddress != 0 && enigmaAddress == 0);
    // require(_engns != 0 && engns == 0);
    enigmaAddress = _enigmaAddress;
    engns = _engns;
    rootNode = _rootNode;
  }

  /*
   * Creates a new auction.
   * NOTE: _startingPrice must be specified in wei.
   */
  function createAuction(uint _auctionLength, uint _startingPrice, bytes32 _name) external returns (address) {
    require(auctions[_name] == 0);
    ENGNSAuction auction = new ENGNSAuction(msg.sender, _auctionLength, _startingPrice, enigmaAddress, this, _name);
    auctions[_name] = auction;
    emit newAuction(auction);
  }

  /**
    * @dev Assign the owner in ENS, if we're still the registrar
    *
    * @param _hash hash to change owner
    * @param _newOwner new owner to transfer to
    */
  function trySetSubnodeOwner(bytes32 _hash, address _newOwner) external {
      if (engns.owner(rootNode) == address(this))
          engns.setSubnodeOwner(rootNode, _hash, _newOwner);
  }
  /*
   * Get every auction address created.
   */
  function getAuctionAddress(bytes32 _name) public view returns (address) {
    return auctions[_name];
  }

}