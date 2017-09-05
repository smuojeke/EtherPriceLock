pragma solidity ^0.4.13;
import "oraclizeAPI.sol";

contract PiggyBank is usingOraclize{

  address public owner;
  uint256 public priceThresholdInUsd;
  uint256 public unlockTimestamp;
  uint256 public bankBalance;
  uint256 public ETHUSD;

  function PiggyBank(uint256 _priceThresholdInUsd, uint256 _unlockTimestamp) {
    owner = msg.sender;
    priceThresholdInUsd = _priceThresholdInUsd;
    unlockTimestamp = _unlockTimestamp;
    isPriceLocked();
  }

  /** Modifiers */
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier timeLocked {
    require(isTimeLocked);
    _;
  }

  modifier priceLocked {
    require(isPriceLocked);
    _;
  }
  /** END Modifiers */

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
    deposit(msg.value);
  }

  function deposit(uint256 _amount) payable returns(bool) {
    bankBalance += _amount;
  }

  function isTimeLocked() constant returns(bool) {
    return (block.timestamp >= unlockTimestamp);
  }

  function updatePrice() {
    oraclize_query("URL", "json(https://api.etherscan.io/api?module=stats&action=ethprice).result.ethusd");
  }

  function isPriceLocked() constant returns(bool) {
    return (ETHUSD >= priceThresholdInUsd);
  }

  // function isLocked() constant returns(bool) {
  //   return (isTimeLocked && isPriceLocked);
  // }

  function withdraw(uint256 _amount, address _to) priceLocked timeLocked onlyOwner {
    _to.transfer(_amount);
  }

  function withdrawAll(address _to) priceLocked timeLocked onlyOwner {
    _to.transfer(bankBalance);
  }

}
