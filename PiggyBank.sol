pragma solidity ^0.4.13;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract PiggyBank is usingOraclize{

  address public owner;
  uint256 public priceThresholdInUsd;
  uint256 public unlockTimestamp;
  uint256 public bankBalance;
  uint256 public ETHUSD;

  function PiggyBank(uint256 priceThresholdInUsd, uint256 unlockTimestamp) {
    owner = msg.sender;
    priceThresholdInUsd = priceThresholdInUsd;
    unlockTimestamp = unlockTimestamp;
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

  function __callback(bytes32 myid, string result) {
      if (msg.sender != oraclize_cbAddress()) throw;
      ETHUSD = result;
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

  function updatePrice() constant {
    oraclize.query("URL", "json(https://api.etherscan.io/api?module=stats&action=ethprice).result.ethusd");
  }

  function isPriceLocked() constant returns(bool) {
    return (ETHUSD >= priceThresholdInUsd);
  }

  function isLocked() constant returns(bool) {
    return (isTimeLocked && isPriceLocked);
  }

  function withdraw(uint256 _amount, address _to) isPriceLocked isTimeLocked onlyOwner {
    _to.transfer(_amount);
  }

  function withdrawAll(address _to) isPriceLocked isTimeLocked onlyOwner {
    _to.transfer(bankBalance);
  }

}
