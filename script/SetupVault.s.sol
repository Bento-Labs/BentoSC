// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/vault/VaultCore.sol";
import "../src/OracleRouter.sol";
import {Addresses} from "./Addresses.sol";
import {Generalized4626Strategy} from "../src/strategy/Generalized4626Strategy.sol";
import "../src/test/TestERC4626.sol";
import {VaultStorage} from "../src/vault/VaultStorage.sol";

contract SetupVault is Script {
    function run() external {
        bool setBentoUSD = false;
        bool setOracleRouter = false;
        bool setAssets = false;
        bool setAssetPriceFeeds = false;
        bool deployStrategies = false;
        bool setAssetStrategies = false;
        bool setLTToken = true;
        // Load private key and addresses
        uint256 deployerPrivateKey = vm.envUint("BentoSepoliaDeployerPrivateKey");
        address owner = vm.addr(deployerPrivateKey);
        
        // Contract addresses - replace with your deployed addresses
        address vaultAddress = 0x8FDE145B1289a99C6B15f363309d3cc9276c0b16; // From your deployment
        VaultCore vault = VaultCore(vaultAddress);
        console.log("Vault address:", vaultAddress);

        vm.startBroadcast(deployerPrivateKey);
        if (setBentoUSD) {
            vault.setBentoUSD(0x6ae08082387AaBcA74830054B1f3ba8a0571F9c6);
        }
        address oracleRouterAddress;
        if (setOracleRouter) {
            vault.setOracleRouter(oracleRouterAddress);
        } else {
            oracleRouterAddress = vault.oracleRouter();
        }
        OracleRouter oracleRouter = OracleRouter(oracleRouterAddress);

        console.log("Setting up vault at address:", vaultAddress);
        console.log("Using oracle router at address:", oracleRouterAddress);


        // Setup price feeds in oracle router
        console.log("Adding price feeds to oracle router...");
        
        if (setAssetPriceFeeds) {
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
        }   

        // Setup assets in vault
        console.log("Setting assets in vault...");
        
        if (setAssets) {
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
        }
        address USDC_Vault = address(0);
        address DAI_Vault = address(0);
        address USDT_Vault = address(0);
        address USDe_Vault = address(0);
        address USDC_Strategy = address(0);
        address DAI_Strategy = address(0);
        address USDT_Strategy = address(0);
        address USDe_Strategy = address(0);
        if (deployStrategies) {
            USDC_Vault = address(new TestERC4626(IERC20(Addresses.SEPOLIA_USDC), "sUSDC", "sUSDC"));
            DAI_Vault = address(new TestERC4626(IERC20(Addresses.SEPOLIA_DAI), "sDAI", "sDAI"));
            USDT_Vault = address(new TestERC4626(IERC20(Addresses.SEPOLIA_USDT), "sUSDT", "sUSDT"));
            USDe_Vault = address(new TestERC4626(IERC20(Addresses.SEPOLIA_USDe), "sUSDe", "sUSDe"));

            USDC_Strategy = address(new Generalized4626Strategy(Addresses.SEPOLIA_USDC, USDC_Vault, address(vault)));
            DAI_Strategy = address(new Generalized4626Strategy(Addresses.SEPOLIA_DAI, DAI_Vault, address(vault)));
            USDT_Strategy = address(new Generalized4626Strategy(Addresses.SEPOLIA_USDT, USDT_Vault, address(vault)));
            USDe_Strategy = address(new Generalized4626Strategy(Addresses.SEPOLIA_USDe, USDe_Vault, address(vault)));

        }
        if (setAssetStrategies) {
            vault.setStrategy(Addresses.SEPOLIA_USDC, USDC_Strategy);
            vault.setStrategy(Addresses.SEPOLIA_DAI, DAI_Strategy);
            vault.setStrategy(Addresses.SEPOLIA_USDT, USDT_Strategy);
            vault.setStrategy(Addresses.SEPOLIA_USDe, USDe_Strategy);
        }

        if (setLTToken) {
            VaultStorage.Asset[] memory vaultAssets = vault.getAssets();
            console.log("\n=== Supported Assets ===");
            uint8[4] memory weights = [50, 75, 25, 50];
            for (uint i = 0; i < vaultAssets.length; i++) {
                address asset = vault.allAssets(i);
                VaultStorage.Asset memory assetInfo = vaultAssets[i];
                IERC20Metadata token = IERC20Metadata(asset);

                console.log("Setting LT token for", token.name());
                address assetStrategy = vault.assetToStrategy(asset);
                address ltToken = Generalized4626Strategy(assetStrategy).shareToken();
                console.log("LT token:", ltToken);
                vault.changeAsset(asset, 18, weights[i], ltToken);
                
            }
        }

        vm.stopBroadcast();

        console.log("Setup complete!");
    }
} 