// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Interactions} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        // Get the active network configuration
        HelperConfig helperConfig = new HelperConfig();
        // Get the configuration for the active network
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 keyHash,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            bool enableNativePayment
        ) = helperConfig.activeNetworkConfig();

        // Check if the subscription ID is 0, indicating that a new subscription needs to be created
        if (subscriptionId == 0) {
            // Create a new subscription using the Interactions contract
            Interactions interactions = new Interactions();
            subscriptionId = interactions.createSubscription(vrfCoordinator);
        }

        vm.startBroadcast();

        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit,
            enableNativePayment
        );

        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
