// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract Interactions is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        // Get the configuration for the active network
        (, , address vrfCoordinator, , , , ) = helperConfig
            .activeNetworkConfig();
        // Create a new subscription using the VRF coordinator address
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint64) {
        // Create a new subscription using the VRF coordinator address
        console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console.log("Subscription ID: ", subId);
        console.log("update subscription id in HelperConfig.s.sol");
        return subId;
    }

    function run() external returns (uint64) {
        // Create a new subscription using the configuration
        uint64 subscriptionId = createSubscriptionUsingConfig();
        return subscriptionId;
    }
}
