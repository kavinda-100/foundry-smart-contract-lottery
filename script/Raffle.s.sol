// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle) {
        uint256 entranceFee = 0.01 ether;
        uint256 interval = 30; // 30 seconds
        address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
        bytes32 keyHash = 0xAA77729D3466CA35AE8D28B9B7C701C2E4A2A1E5F4F4F4F4F4F4F4F4F4F4F4F4;
        uint64 subscriptionId = 12345; // Replace with your subscription ID
        uint32 callbackGasLimit = 100000; // Adjust as needed
        bool enableNativePayment = false; // Set to true if you want to accept native payments

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

        return raffle;
    }
}
