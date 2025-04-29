// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol"; // Import the LinkToken contract
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract Interactions is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        // Get the configuration for the active network
        (, , address vrfCoordinator, , , , , ) = helperConfig
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

contract FundSubscriptions is Script {
    uint96 public constant FUND_AMOUNT = 3 ether; // Amount to fund the subscription

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        // Get the configuration for the active network
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            ,
            address linkToken
        ) = helperConfig.activeNetworkConfig();

        fundSubscriptions(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscriptions(
        address vrfCoordinator,
        uint64 subscriptionId,
        address linkToken
    ) public {
        console.log("Funding subscription on chainId: ", block.chainid);
        console.log("Funding subscription ID: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("Funding subscription with linkToken: ", linkToken);

        if (block.chainid == 31337) {
            vm.startBroadcast();
            // Fund the subscription with LINK tokens
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );

            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address contractAddress) public {
        HelperConfig helperConfig = new HelperConfig();
        // Get the configuration for the active network
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            ,

        ) = helperConfig.activeNetworkConfig();

        addConsumer(contractAddress, vrfCoordinator, subscriptionId);
    }

    function addConsumer(
        address contractAddress,
        address vrfCoordinator,
        uint64 subscriptionId
    ) public {
        console.log("Adding consumer to subscription ID: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("Using consumer contract: ", contractAddress);

        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            contractAddress
        );
        vm.stopBroadcast();
    }

    function run() external {
        address contractAddress = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(contractAddress);
    }
}
