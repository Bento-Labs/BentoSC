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
        bool setAssets = true;
        bool setAssetPriceFeeds = true;
        bool deployStakingVaults = false;
        bool deployStrategies = true;
        bool setAssetStrategies = true;
        bool setLTToken = false;

        /* string memory rpcUrl = vm.rpcUrl(); 
        console.log("Using RPC URL:", rpcUrl); */
        uint256 deployerPrivateKey;
        address owner;
        address vaultAddress;
        address bentoUSDAddress;
        address oracleRouterAddress;
        address DAIAddress;
        address USDCAddress;
        address USDTAddress;
        address USDeAddress;
        uint32 DAIWeight;
        uint32 USDCWeight;
        uint32 USDTWeight;
        uint32 USDeWeight;
        address DAI_USD_FEED;
        address USDC_USD_FEED;
        address USDT_USD_FEED;
        address USDe_USD_FEED;
        address sDAIAddress;
        address sUSDCAddress;
        address sUSDTAddress;
        address sUSDeAddress;
        uint8 DAI_decimals;
        uint8 USDC_decimals;
        uint8 USDT_decimals;
        uint8 USDe_decimals;
        address USDC_Strategy;
        address DAI_Strategy;
        address USDT_Strategy;
        address USDe_Strategy;
        /* if (rpcUrl == vm.envString("TenderlyMainnetRPC"))  */
        if (true) {
            // Load private key and addresses
            deployerPrivateKey = vm.envUint("BentoMainnetDeployerPrivateKey");
            owner = vm.addr(deployerPrivateKey);
            // Contract addresses - replace with your deployed addresses
            vaultAddress = 0x2DC4Da4832604f886A81120dB11108057f6D6BAf; // From your deployment
            bentoUSDAddress = 0xfeD4BB1f4Ce7C74e23BE2B968E2962431726d4f3;
            oracleRouterAddress = 0x8274713D419da3531DfAe1e9ed89d6F9c359cc4d;
            DAIAddress = Addresses.DAI;
            USDCAddress = Addresses.USDC;
            USDTAddress = Addresses.USDT;
            USDeAddress = Addresses.USDe;
            DAIWeight = 250;
            USDCWeight = 375;
            USDTWeight = 125;
            USDeWeight = 250;
            DAI_USD_FEED = Addresses.DAI_USD_FEED;
            USDC_USD_FEED = Addresses.USDC_USD_FEED;
            USDT_USD_FEED = Addresses.USDT_USD_FEED;
            USDe_USD_FEED = Addresses.USDe_USD_FEED;
            DAI_decimals = 18;
            USDC_decimals = 6;
            USDT_decimals = 6;
            USDe_decimals = 18;
            sDAIAddress = Addresses.sDAI;
            sUSDCAddress = Addresses.sUSDC;
            sUSDTAddress = Addresses.sUSDT;
            sUSDeAddress = Addresses.sUSDe;
            

        }

        VaultCore vault = VaultCore(vaultAddress);
        console.log("Vault address:", vaultAddress);
        BentoUSD bentoUSD = BentoUSD(bentoUSDAddress);

        vm.startBroadcast(deployerPrivateKey);
        console.log("owner address:", owner);
        if (setBentoUSD) {
            console.log("governor is:", vault.governor());
            console.log("bentoUSDVault is:", bentoUSD.bentoUSDVault());
            
            console.log("Setting bentoUSD to:", bentoUSDAddress); 
            console.log("Current bentoUSD is:", vault.bentoUSD());
            vault.setBentoUSD(bentoUSDAddress);
        }

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
                DAIAddress,
                DAI_USD_FEED,
                86400, // 1 day staleness
                8     // decimals
            );

            oracleRouter.addFeed(
                USDCAddress,
                USDC_USD_FEED,
                86400,
                8
            );

            oracleRouter.addFeed(
                USDTAddress,
                USDT_USD_FEED,
                86400,
                8
            );

            oracleRouter.addFeed(
                USDeAddress,
                USDe_USD_FEED,
                86400,
                8
                );
        }   

        // Setup assets in vault
        console.log("Setting assets in vault...");
        
        if (setAssets) {
            // Set assets with equal weights (25% each)
            vault.setAsset(
            USDCAddress,
            USDC_decimals,      // USDC decimals
            USDCWeight,     // 25% weight
            sUSDCAddress
        );

        vault.setAsset(
            DAIAddress,
            DAI_decimals,     // DAI decimals
            DAIWeight,     // 25% weight
            sDAIAddress
        );

        vault.setAsset(
            USDTAddress,
            USDT_decimals,      // USDT decimals
            USDTWeight,     // 25% weight
            sUSDTAddress
        );

        vault.setAsset(
            USDeAddress,
            USDe_decimals,     // USDe decimals
            USDeWeight,     // 25% weight
            sUSDeAddress
            );
        }
        address USDC_Vault = address(0);
        address DAI_Vault = address(0);
        address USDT_Vault = address(0);
        address USDe_Vault = address(0);
        if (deployStakingVaults) {
            USDC_Vault = address(new TestERC4626(IERC20(Addresses.SEPOLIA_USDC), "sUSDC", "sUSDC"));
            DAI_Vault = address(new TestERC4626(IERC20(Addresses.SEPOLIA_DAI), "sDAI", "sDAI"));
            USDT_Vault = address(new TestERC4626(IERC20(Addresses.SEPOLIA_USDT), "sUSDT", "sUSDT"));
            USDe_Vault = address(new TestERC4626(IERC20(Addresses.SEPOLIA_USDe), "sUSDe", "sUSDe"));
        }

        if (deployStrategies) {
            
            USDC_Strategy = address(new Generalized4626Strategy(USDCAddress, sUSDCAddress, address(vault)));
            DAI_Strategy = address(new Generalized4626Strategy(DAIAddress, sDAIAddress, address(vault)));
            USDT_Strategy = address(new Generalized4626Strategy(USDTAddress, sUSDTAddress, address(vault)));
            USDe_Strategy = address(new Generalized4626Strategy(USDeAddress, sUSDeAddress, address(vault)));

        }
        if (setAssetStrategies) {
            vault.setStrategy(USDCAddress, USDC_Strategy);
            vault.setStrategy(DAIAddress, DAI_Strategy);
            vault.setStrategy(USDTAddress, USDT_Strategy);
            vault.setStrategy(USDeAddress, USDe_Strategy);
        }

        if (setLTToken) {
            VaultStorage.Asset[] memory vaultAssets = vault.getAssets();
            console.log("\n=== Supported Assets ===");
            uint8[4] memory weights = [75, 50, 25, 50];
            for (uint i = 0; i < vaultAssets.length; i++) {
                address asset = vault.allAssets(i);
                VaultStorage.Asset memory assetInfo = vaultAssets[i];
                IERC20Metadata token = IERC20Metadata(asset);

                console.log("Setting LT token for", token.name());
                address assetStrategy = vault.assetToStrategy(asset);
                address ltToken = Generalized4626Strategy(assetStrategy).shareToken();
                console.log("LT token:", ltToken);
                vault.changeAsset(asset, 18, assetInfo.weight, ltToken);
                
            }
        }

        vm.stopBroadcast();

        console.log("Setup complete!");
    }
} 