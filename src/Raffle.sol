// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/***
 * @title Raffle
 * @author kavinda
 * @notice This contract is a simple implementation of a raffle system.
 * @dev The contract allows users to enter a raffle by sending Ether, and the winner is selected randomly.
 */
contract Raffle {
    // State variables
    uint256 private immutable i_entranceFee; // Fee to enter the raffle

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee; // Set the entrance fee
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}

    // getters

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee; // Return the entrance fee
    }
}
