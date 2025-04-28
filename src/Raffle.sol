// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {console} from "forge-std/console.sol";

/***
 * @title Raffle
 * @author kavinda rathnayake
 * @notice This contract is a simple implementation of a raffle system.
 * @dev The contract allows users to enter a raffle by sending Ether, and the winner is selected randomly.
 */
contract Raffle is VRFConsumerBaseV2Plus {
    // custom errors
    error Raffle__NotEnoughETHEntered(); // Error for insufficient ETH
    error Raffle__TransferFailed(); // Error for transfer failure
    error Raffle__NotOpen(); // Error for when the raffle is not open
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    ); // Error for when upkeep is not needed

    // enums/Type declarations
    enum RaffleState {
        OPEN,
        CALCULATING
    } // Enum for the raffle state

    // State variables
    uint256 private immutable i_entranceFee; // Fee to enter the raffle
    uint256 private immutable i_interval; // Time interval for the raffle (in seconds)
    uint256 private s_lastTimeStamp; // Timestamp of the last raffle
    address private immutable i_vrfCoordinator; // Address of the VRF coordinator
    bytes32 private immutable i_keyHash; // Key hash for the VRF
    uint64 private immutable i_subscriptionId; // Subscription ID for the VRF
    uint32 private immutable i_callbackGasLimit; // Gas limit for the callback function
    bool private immutable i_enableNativePayment; // Flag to enable native payment
    address payable[] private s_players; // Array to store players'
    address private s_recentWinner; // Address of the most recent winner
    RaffleState private s_raffleState; // Current state of the raffle

    // constants
    uint16 private constant REQUEST_CONFIRMATIONS = 2; // Number of confirmations required for the VRF request
    uint32 private constant NUM_WORDS = 1; // Number of random words to request

    //events
    event RaffleEnter(address indexed player); // Event emitted when a player enters the raffle
    event WinnerPicked(address indexed winner); // Event emitted when a winner is picked

    /**
     * HARDCODED FOR SEPOLIA
     * COORDINATOR: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        bool enableNativePayment
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee; // Set the entrance fee
        i_interval = interval; // Set the time interval for the raffle
        s_lastTimeStamp = block.timestamp; // Initialize the last timestamp to the current block timestamp
        i_vrfCoordinator = vrfCoordinator; // Set the VRF coordinator address
        i_keyHash = keyHash; // Set the key hash for the VRF
        i_subscriptionId = subscriptionId; // Set the subscription ID for the VRF
        i_callbackGasLimit = callbackGasLimit; // Set the gas limit for the callback function
        i_enableNativePayment = enableNativePayment; // Set the flag to enable native payment
        s_raffleState = RaffleState.OPEN; // Initialize the raffle state to OPEN
    }

    function enterRaffle() public payable {
        // Check if the sent value is less than the entrance fee
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered(); // Revert with custom error
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen(); // Revert if the raffle is not open
        }
        // Add the player's address to the players array
        s_players.push(payable(msg.sender)); // Store the player's address
        // emit the RaffleEnter event
        emit RaffleEnter(msg.sender); // Emit the event
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call to check if upkeep is needed.
     * It returns a boolean value indicating whether upkeep is needed and any additional data required for the upkeep.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool hasPlayers = (s_players.length > 0); // Check if there are players in the raffle
        bool hasBalance = (address(this).balance > 0); // Check if the contract has a balance
        upkeepNeeded = (timeHasPassed && isOpen && hasPlayers && hasBalance); // Determine if upkeep is needed
        return (upkeepNeeded, "0x0"); // Return the upkeep status and empty performData
    }

    function performUpkeep(bytes calldata /* performData */) external {
        // Check if upkeep is needed
        (bool upkeepNeeded, ) = checkUpkeep(""); // Call the checkUpkeep function
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            ); // Revert if upkeep is not needed
        }

        s_raffleState = RaffleState.CALCULATING; // Set the raffle state to CALCULATING
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: i_enableNativePayment
                    })
                )
            })
        );
        console.log("requestId: ", requestId); // Log the request ID for debugging
    }

    function fulfillRandomWords(
        uint256 /** requestId */,
        uint256[] calldata randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length; // Get a random index for the winner
        address payable winner = s_players[winnerIndex]; // Get the winner's address
        s_recentWinner = winner; // Set the recent
        s_raffleState = RaffleState.OPEN; // Set the raffle state back to OPEN
        s_players = new address payable[](0); // Reset the players array for the next raffle
        s_lastTimeStamp = block.timestamp; // Update the last timestamp to the current block timestamps
        (bool success, ) = winner.call{value: address(this).balance}(""); // Transfer the balance to the
        if (!success) {
            revert Raffle__TransferFailed(); // Revert if the transfer fails
        }

        emit WinnerPicked(winner); // Emit the event with the winner's address
    }

    // getters

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee; // Return the entrance fee
    }

    function getInterval() public view returns (uint256) {
        return i_interval; // Return the time interval for the raffle
    }

    function getPlayers() public view returns (address payable[] memory) {
        return s_players; // Return the array of players' addresses
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner; // Return the address of the most recent winner
    }
}
