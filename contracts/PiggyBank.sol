pragma solidity ^0.4.13;
import "oraclizeAPI.sol";

contract PiggyBank is usingOraclize{

  address public owner;
  uint256 public priceThresholdInUsd;
  uint256 public unlockTimestamp;
  uint256 public bankBalance;
  uint256 public ETHUSD;
  mapping(address => Hodler) public hodlers;

  struct Piggy {
    uint256 balance;
    address owner;
    uint256 priceThresholdInUsd;
    uint256 unlockTimestamp;
    string name;
    bool exists;
  }

  struct Hodler {
    string[] piggyList;
    mapping(string => Piggy) piggies;
    address owner;
    bool exists;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyHodler {
    require(hodlers[msg.sender].exists);
    _;
  }

  function depositToPiggy(string _piggyName) payable onlyHodler {
    var hodler = hodlers[msg.sender];
    require(doesPiggyExist(_piggyName));
    hodler.piggies[_piggyName].balance += msg.value;
  }

  function withdrawFromPiggy(string _piggyName) onlyHodler {
    var hodler = hodlers[msg.sender];
    require(doesPiggyExist(_piggyName));
    require(hodler.piggies[_piggyName].balance > 0);
    require(!isPiggyLocked(_piggyName));
    var transferAmount = hodler.piggies[_piggyName].balance;
    hodler.piggies[_piggyName].balance = 0;
    msg.sender.transfer(transferAmount);
  }


  function createPiggybank(uint256 _priceThresholdInUsd, uint256 _unlockTimestamp, string _piggyName) {
    // Set up new hodler if not already existing
    if (!hodlers[msg.sender].exists) {
      hodlers[msg.sender].owner = msg.sender;
      hodlers[msg.sender].exists = true;
    }
    require(hodlers[msg.sender].piggies[_piggyName].exists);
    // Set up new piggy bank
    var new_piggy = hodlers[msg.sender].piggies[_piggyName];
    new_piggy.owner = msg.sender;
    new_piggy.priceThresholdInUsd = _priceThresholdInUsd;
    new_piggy.unlockTimestamp = _unlockTimestamp;
    new_piggy.name = _piggyName;
    new_piggy.exists = true;
    // Save piggy bank name to list, and new piggy bank
    hodlers[msg.sender].piggyList.push(_piggyName);
  }

  event LogPiggyBankName(string piggy_name);
  function getPiggyNames() {
    var hodler = hodlers[msg.sender];
    if (hodler.exists) {
      var numOfPiggies = hodler.piggyList.length;
      for (var i = 0; i < numOfPiggies; i++) {
        LogPiggyBankName(hodler.piggyList[i]);
      }
    }
  }

  function doesPiggyExist(string _piggyName) returns (bool) {
    return (hodlers[msg.sender].piggies[_piggyName].exists);
  }

  function getPiggyBalance(string _piggyName) onlyHodler returns (uint256) {
    if (!doesPiggyExist(_piggyName)) return 0;

    return hodlers[msg.sender].piggies[_piggyName].balance;
  }

  function isPiggyLocked(string _piggyName) onlyHodler returns (bool) {
    if (!doesPiggyExist(_piggyName)) return false;

    var hodler = hodlers[msg.sender];
    var piggy = hodler.piggies[_piggyName];
    return ((block.timestamp >= piggy.unlockTimestamp) && (ETHUSD >= piggy.priceThresholdInUsd));
  }

  function PiggyBank() {
    owner = msg.sender;
  }

  function stringToUint(string s) constant returns (uint result) {
      bytes memory b = bytes(s);
      uint i;
      result = 0;
      for (i = 0; i < b.length; i++) {
          uint c = uint(b[i]);
          if (c >= 48 && c <= 57) {
              result = result * 10 + (c - 48);
          }
      }
  }

  function __callback(bytes32 myid, string result) {
    if (msg.sender != oraclize_cbAddress()) throw;
      ETHUSD = stringToUint(result);
  }

  function() payable {
  }

  function updatePrice() {
    oraclize_query("URL", "json(https://api.etherscan.io/api?module=stats&action=ethprice).result.ethusd");
  }
}
