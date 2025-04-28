// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/***
 * @title Raffle
 * @author kavinda
 * @notice This contract is a simple implementation of a raffle system.
 * @dev The contract allows users to enter a raffle by sending Ether, and the winner is selected randomly.
 */
contract Raffle {
    // custom errors
    error Raffle__NotEnoughETHEntered(); // Error for insufficient ETH sent
    // State variables
    uint256 private immutable i_entranceFee; // Fee to enter the raffle
    address payable[] private s_players; // Array to store players' addresses

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee; // Set the entrance fee
    }

    function enterRaffle() public payable {
        // Check if the sent value is less than the entrance fee
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered(); // Revert with custom error
        }
        // Add the player's address to the players array
        s_players.push(payable(msg.sender)); // Store the player's address
    }

    function pickWinner() public {}

    // getters

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee; // Return the entrance fee
    }
}
