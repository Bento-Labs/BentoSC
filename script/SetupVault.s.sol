// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/vault/VaultCore.sol";
import "../src/OracleRouter.sol";
import {Addresses} from "./Addresses.sol";

contract SetupVault is Script {
    function run() external {
        // Load private key and addresses
        uint256 deployerPrivateKey = vm.envUint("BentoSepoliaDeployerPrivateKey");
        address owner = vm.addr(deployerPrivateKey);
        
        // Contract addresses - replace with your deployed addresses
        address vaultAddress = 0x8FDE145B1289a99C6B15f363309d3cc9276c0b16; // From your deployment
        VaultCore vault = VaultCore(vaultAddress);
        console.log("Vault address:", vaultAddress);

        vm.startBroadcast(deployerPrivateKey);
        address oracleRouterAddress = address(0); // From your deployment
        if (oracleRouterAddress != address(0)) {
            vault.setOracleRouter(oracleRouterAddress);
        } else {
            oracleRouterAddress = vault.oracleRouter();
        }
        OracleRouter oracleRouter = OracleRouter(oracleRouterAddress);

        console.log("Setting up vault at address:", vaultAddress);
        console.log("Using oracle router at address:", oracleRouterAddress);


        // Setup price feeds in oracle router
        console.log("Adding price feeds to oracle router...");
        
        // Sepolia addresses from Addresses.sol
        oracleRouter.addFeed(
            Addresses.SEPOLIA_DAI,
            Addresses.SEPOLIA_DAI_USD_FEED,
            86400, // 1 day staleness
            8     // decimals
        );

        oracleRouter.addFeed(
            Addresses.SEPOLIA_USDC,
            Addresses.SEPOLIA_USDC_USD_FEED,
            86400,
            8
        );

        oracleRouter.addFeed(
            Addresses.SEPOLIA_USDT,
            Addresses.SEPOLIA_USDT_USD_FEED,
            86400,
            8
        );

        oracleRouter.addFeed(
            Addresses.SEPOLIA_USDe,
            Addresses.SEPOLIA_USDe_USD_FEED,
            86400,
            8
        );

        // Setup assets in vault
        console.log("Setting assets in vault...");
        
        // Set assets with equal weights (25% each)
        vault.setAsset(
            Addresses.SEPOLIA_USDC,
            6,      // USDC decimals
            25,     // 25% weight
            address(0)  // No LT token initially
        );

        vault.setAsset(
            Addresses.SEPOLIA_DAI,
            18,     // DAI decimals
            25,     // 25% weight
            address(0)
        );

        vault.setAsset(
            Addresses.SEPOLIA_USDT,
            6,      // USDT decimals
            25,     // 25% weight
            address(0)
        );

        vault.setAsset(
            Addresses.SEPOLIA_USDe,
            18,     // USDe decimals
            25,     // 25% weight
            address(0)
        );

        vm.stopBroadcast();

        console.log("Setup complete!");
    }
} 