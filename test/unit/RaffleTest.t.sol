// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/Raffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    // State variables ///////////////////////////////////////////////////////////////////////////////////////
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

    // fake data for testing ///////////////////////////////////////////////////////////////////////////////////////
    address public PLAYER = makeAddr("player"); // Fake player address
    uint256 public constant STARTING_USER_BALANCE = 10 ether; // Starting balance for the player
    uint256 public constant ENTRANCE_FEE = 0.05 ether; // Entrance fee for the raffle

    // Events for the tests ///////////////////////////////////////////////////////////////////////////////////////
    event RaffleEnter(address indexed player); // Event emitted when a player enters the raffle

    //   // Set up function ///////////////////////////////////////////////////////////////////////////////////////
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

    // Modifiers ///////////////////////////////////////////////////////////////////////////////////////

    /**@dev This modifier is used to set up the test environment for entering the raffle and passing the time interval.*/
    modifier raffleEnterAndTimePassed() {
        vm.prank(PLAYER); // Start prank as the player
        raffle.enterRaffle{value: ENTRANCE_FEE}(); // Player enters the raffle
        vm.warp(block.timestamp + interval + 1); // Move forward in time to trigger upkeep
        vm.roll(block.number + 1); // Move to the next block
        _; // Continue with the rest of the test
    }

    /**@dev This modifier is used to skip the forked network tests.*/
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    // Tests ///////////////////////////////////////////////////////////////////////////////////////

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
    function testCanNotEnterWhenRaffleIsCalculating()
        external
        raffleEnterAndTimePassed
    {
        // Arrange and Act in the modifier
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
    function testCheckUpKeepReturnsFalseIfRaffleIsNotOpen()
        external
        raffleEnterAndTimePassed
    {
        // Arrange and Act in the modifier

        raffle.performUpkeep(""); // Perform upkeep to change the state to CALCULATING

        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // Check if upkeep is needed

        // Assert
        assert(!upkeepNeeded); // Check if upkeep is not needed (should be false)
    }

    /**
     *  @dev This test ensures that the checkUpkeep function returns false if the time interval has not passed.
     */
    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue()
        external
        raffleEnterAndTimePassed
    {
        // Arrange

        // Act
        // Assert
        raffle.checkUpkeep(""); // Check if upkeep is needed
    }

    /**
     *  @dev This test ensures that the performUpkeep function reverts if checkUpkeep returns false.
     *  It uses the `vm.expectRevert` function to expect a revert with the custom error `Raffle__UpkeepNotNeeded`.
     */
    function testPerformUpKeepRevertIfCheckUpKeepIsFalse() external {
        // Arrange
        uint256 currentBalance = 0; // Set current balance to 0
        uint256 numPlayers = 0; // Set number of players to 0
        uint256 raffleState = 0; // Set raffle state to 0 (OPEN)

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        ); // Expect revert with custom error
        raffle.performUpkeep(""); // Attempt to perform upkeep (should revert)
    }

    /**
     *  @dev This test ensures that the performUpkeep function can only be called when checkUpkeep returns true.
     */
    function testFullFillRandomWordsCanOnlyBeCalledAfterPerformUpkeep()
        external
        raffleEnterAndTimePassed
        skipFork
    {
        // Arrange
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector); // Attempt to fulfill random words (should revert)
        // Assert
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            0,
            address(raffle)
        ); // Attempt to fulfill random words (should revert)
    }

    function testFullFillRandomWordsPickWinnerRestAndSendMoney()
        external
        raffleEnterAndTimePassed
        skipFork
    {
        // Arrange
        address expectedWinner = address(1); // Expected winner address
        uint256 additionalEntrance = 3; // Number of additional players to enter
        uint256 startingIndex = 1; // Starting index for the additional players

        for (uint256 i = startingIndex; i < additionalEntrance; i++) {
            address player = address(uint160(i)); // Generate a fake player address
            hoax(player, 10 ether); // Fake player address and fund them with entrance fee
            raffle.enterRaffle{value: ENTRANCE_FEE}(); // Player enters the raffle
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp(); // Get the starting timestamp
        uint256 startingBalance = expectedWinner.balance; // Get the starting balance of the expected winner

        vm.recordLogs(); // Record logs for later verification
        raffle.performUpkeep(""); // Perform upkeep to change the state to CALCULATING
        Vm.Log[] memory entries = vm.getRecordedLogs(); // Get recorded logs
        bytes32 requestId = entries[1].topics[1]; // Get the request ID from the logs

        // Act
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId), // Convert request ID to uint256
            address(raffle)
        );

        // Assert
        address recentWinner = raffle.getRecentWinner(); // Get the recent winner address
        Raffle.RaffleState raffleState = raffle.getRaffleState(); // Get the current raffle state
        uint256 winnerBalance = recentWinner.balance; // Get the winner's balance
        uint256 endingTimestamp = raffle.getLastTimeStamp(); // Get the previous timestamp
        uint256 prize = ENTRANCE_FEE * (additionalEntrance + 1); // Calculate the total prize amount

        assert(recentWinner == expectedWinner); // Check if the recent winner matches the expected winner
        assert(uint256(raffleState) == 0); // Check if the raffle state is OPEN (0)
        assert(winnerBalance == startingBalance + prize); // Check if the winner's balance is correct
        assert(endingTimestamp > startingTimeStamp); // Check if the ending timestamp is greater than the starting timestamp
    }
}
