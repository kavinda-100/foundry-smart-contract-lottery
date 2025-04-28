// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash; // gas lane key hash
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        bool enableNativePayment;
    }
}
