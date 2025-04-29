// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/Raffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract RaffleTest is Test {
    // State variables
    Raffle raffle; // Raffle contract instance
    HelperConfig helperConfig; // HelperConfig instance
    uint256 entranceFee; // Entrance fee for the raffle
    uint256 interval; // Time interval for the raffle (in seconds)
    address vrfCoordinator; // Address of the VRF coordinator
    bytes32 keyHash; // Key hash for the VRF
    uint64 subscriptionId; // Subscription ID for the VRF
    uint32 callbackGasLimit; // Gas limit for the callback function
    bool enableNativePayment; // Flag to enable native payment

    // fake data for testing
    address public PLAYER = makeAddr("player"); // Fake player address
    uint256 public constant STARTING_USER_BALANCE = 10 ether; // Starting balance for the player

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit,
            enableNativePayment
        ) = helperConfig.activeNetworkConfig();
    }

    function testJust() external pure {
        // This is a placeholder test function that does nothing.
        // It can be used to check if the test suite is running correctly.
        assert(true); // Always pass
    }
}

// function setUp() external {
//         // Initialize the helperConfig and get the active network configuration
//         helperConfig = new HelperConfig();
//         (
//             entranceFee,
//             interval,
//             vrfCoordinator,
//             keyHash,
//             subscriptionId,
//             callbackGasLimit,
//             enableNativePayment
//         ) = helperConfig.activeNetworkConfig();

//         // Deploy the Raffle contract directly
//         raffle = new Raffle(
//             entranceFee,
//             interval,
//             vrfCoordinator,
//             keyHash,
//             subscriptionId,
//             callbackGasLimit,
//             enableNativePayment
//         );

//         // Fund the PLAYER address with the starting balance
//         vm.deal(PLAYER, STARTING_USER_BALANCE);
//     }
