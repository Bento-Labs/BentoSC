// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/vault/VaultCore.sol";
import "../src/OracleRouter.sol";
import {Addresses} from "./Addresses.sol";

contract Playground is Script {
    function run() external {
        // Load private key and addresses
        uint256 deployerPrivateKey = vm.envUint("BentoSepoliaDeployerPrivateKey");
        address owner = vm.addr(deployerPrivateKey);

        // Check if we're on a fork
        string[2][] memory allUrls = vm.rpcUrls();
        console.log("number of rpc urls:", allUrls.length);
        for (uint256 i = 0; i < allUrls.length; i++) {
            console.log("RPC name:", allUrls[i][0]);
            console.log("RPC url:", allUrls[i][1]);
        }
    }
} 