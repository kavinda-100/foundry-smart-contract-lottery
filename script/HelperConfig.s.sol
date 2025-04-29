// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script {
    // struct to hold the configuration for the network
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash; // gas lane key hash
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        bool enableNativePayment;
        address linkToken; // Address of the LINK token contract
    }

    NetworkConfig public activeNetworkConfig; // variable to hold the active network configuration

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30, // 30 seconds
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 0, // Replace with your subscription ID
                callbackGasLimit: 500000, // Adjust as needed
                enableNativePayment: false, // Set to true if you want to accept native payments
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig; // Return the existing configuration if it exists
        }
        uint96 baseFee = 0.25 ether; // Base fee for the mock VRF coordinator (0.25 LINK per request)
        uint96 gasPriceLink = 1e9; // Gas price for LINK token (1 Gwei LINK per gas)

        vm.startBroadcast();

        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );

        vm.stopBroadcast();

        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30, // 30 seconds
                vrfCoordinator: address(vrfCoordinator),
                keyHash: 0xAA77729D3466CA35AE8D28B9B7C701C2E4A2A1E5F4F4F4F4F4F4F4F4F4F4F4F4,
                subscriptionId: 0, // Replace with your subscription ID
                callbackGasLimit: 500000, // Adjust as needed
                enableNativePayment: false, // Set to true if you want to accept native payments
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }
}
