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
    uint256 subscriptionId; // Subscription ID for the VRF
    uint32 callbackGasLimit; // Gas limit for the callback function
    bool enableNativePayment; // Flag to enable native payment
    address linkToken; // Address of the LINK token contract

    // fake data for testing
    address public PLAYER = makeAddr("player"); // Fake player address
    uint256 public constant STARTING_USER_BALANCE = 10 ether; // Starting balance for the player
    uint256 public constant ENTRANCE_FEE = 0.05 ether; // Entrance fee for the raffle

    // Events for the tests
    event RaffleEnter(address indexed player); // Event emitted when a player enters the raffle

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
            enableNativePayment,
            linkToken
        ) = helperConfig.activeNetworkConfig();

        // Fund the player with some ether
        vm.deal(PLAYER, STARTING_USER_BALANCE); // Give the player some ether
    }

    /**
     *  @dev This test ensures that user can't enter the raffle without sending enough ETH.
     *  It uses the `vm.expectRevert` function to expect a revert with the custom error `Raffle__NotEnoughETHEntered`.
     */
    function testRaffleRevertWhenYouPayNotEnoughETH() external {
        // Arrange
        vm.prank(PLAYER); // Start prank as the player

        // Act & Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughETHEntered.selector); // Expect revert with custom error
        raffle.enterRaffle(); // Attempt to enter the raffle with insufficient ETH

        vm.stopPrank(); // Stop prank
    }

    /**
     *  @dev This test ensures that contract records players when they enter the raffle.
     */
    function testRaffleRecordPlayersWhenTheyEnter() external {
        // Arrange
        vm.prank(PLAYER); // Start prank as the player

        // Act
        raffle.enterRaffle{value: ENTRANCE_FEE}(); // Player enters the raffle
        address player = raffle.getSinglePlayer(0); // Get the first player from the raffle

        // Assert
        assertEq(player, PLAYER); // Check if the player address matches the expected address
    }

    /**
     *  @dev This test ensures that contract emit the event when a player enters the raffle.
     *  It uses the `vm.expectEmit` function to expect the `RaffleEnter` event to be emitted with the correct parameters.
     */
    function testEmitEventWhenPlayerEntersRaffle() external {
        // Arrange
        vm.prank(PLAYER); // Start prank as the player

        // Act & Assert
        vm.expectEmit(true, false, false, false, address(raffle)); // Expect emit with all parameters set to true
        emit RaffleEnter(PLAYER); // Emit the RaffleEnter event
        raffle.enterRaffle{value: ENTRANCE_FEE}(); // Player enters the raffle
    }

    /**
     *  @dev This test ensures that the raffle can only be entered when it is open.
     *  It uses the `vm.expectRevert` function to expect a revert with the custom error `Raffle__NotOpen`.
     */
    function testCanNotEnterWhenRaffleIsCalculating() external {
        // Arrange
        vm.prank(PLAYER); // Start prank as the player
        raffle.enterRaffle{value: ENTRANCE_FEE}(); // Player enters the raffle

        // Act
        vm.warp(block.timestamp + interval + 1); // Move forward in time to trigger upkeep
        vm.roll(block.number + 1); // Move to the next block
        raffle.performUpkeep(""); // Perform upkeep to change the state to CALCULATING

        // Assert
        vm.expectRevert(Raffle.Raffle__NotOpen.selector); // Expect revert with custom error
        vm.prank(PLAYER); // Start prank as the player
        raffle.enterRaffle{value: ENTRANCE_FEE}(); // Attempt to enter the raffle again (should revert)
    }

    /**
     *  @dev This test ensures that the checkUpkeep function returns false if the raffle has no balance.
     */
    function testCheckUpKeepReturnFalseIfItHasNoBalance() external {
        // Arrange
        vm.warp(block.timestamp + interval + 1); // Move forward in time to trigger upkeep
        vm.roll(block.number + 1); // Move to the next block

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // Check if upkeep is needed

        // Assert
        assert(!upkeepNeeded); // Check if upkeep is not needed (should be false)
    }

    /**
     *  @dev This test ensures that the checkUpkeep function returns false if the raffle is not open.
     */
    function testCheckUpKeepReturnsFalseIfRaffleIsNotOpen() external {
        // Arrange
        vm.prank(PLAYER); // Start prank as the player
        raffle.enterRaffle{value: ENTRANCE_FEE}(); // Player enters the raffle

        // Act
        vm.warp(block.timestamp + interval + 1); // Move forward in time to trigger upkeep
        vm.roll(block.number + 1); // Move to the next block
        raffle.performUpkeep(""); // Perform upkeep to change the state to CALCULATING

        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // Check if upkeep is needed

        // Assert
        assert(!upkeepNeeded); // Check if upkeep is not needed (should be false)
    }
}
