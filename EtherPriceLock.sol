pragma solidity ^0.4.11;

import "./ExchangeRate.sol"

contract EtherPriceLock {

    // Keep track of the original contract owner
    address owner;
    uint unlockTime;
    bool locked;

    event LogDeposit(address addr, uint amount);
    event LogWithdraw(address addr, uint amount);
    event LogUnlockTime(uint unlockTimeX);
    event LogContractCreated(address ownerX);
    event LogWithdrawAttempt(string message, address ownerX, address sender);
    event LogCheckTime(uint currentTime, uint unlockTimeX);

    // Constructor
    function EtherLock() {
        // Who owns this contract?
        owner = msg.sender;
        locked = true;
        LogContractCreated(owner);
    }

    function deposit() payable {
        LogDeposit(msg.sender, msg.value);
    }

    function withdraw() {
      LogWithdrawAttempt("Withdraw Attempt", owner, msg.sender);
        if (msg.sender == owner && !isLocked()) {
            uint amount = this.balance;
            bool success = owner.send(this.balance);
            if (success) {
                LogWithdraw(owner, amount);
            }
        } else if (msg.sender != owner) {
            LogWithdrawAttempt("Failed Withdraw, wrong sender", owner, msg.sender);
        } else if (isLocked()) {
            LogWithdrawAttempt("Failed Withdraw, funds locked", owner, msg.sender);
        }
    }

    function getAmount() constant returns(uint) {
        return this.balance;
    }

    function isLocked() constant returns(bool) {
        LogCheckTime(now, unlockTime);
        if (now < unlockTime) {
          locked = true;
        } else {
          locked = false;
        }
        return locked;
    }

    function setTime(uint futureTime) {
        unlockTime = futureTime;
        LogUnlockTime(unlockTime);
    }

    function getTime() constant returns(uint256) {
        return unlockTime;
    }
}
