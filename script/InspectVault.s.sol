// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/vault/VaultCore.sol";
import "../src/vault/VaultStorage.sol";
import "../src/BentoUSD.sol";
import "../src/OracleRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../src/BentoUSDPlus.sol";

contract InspectVault is Script {
    function run() external view {
        // Load deployed vault address
        address vaultAddress = 0x2DC4Da4832604f886A81120dB11108057f6D6BAf;
        address bentoUSDPlusAddress = 0x36EDED206feFA357f274b60994a9Afa1c1194aEf;
        VaultCore vault = VaultCore(vaultAddress);
        
        // Get BentoUSD and OracleRouter addresses from vault
        address bentoUSDAddress = vault.bentoUSD();
        address oracleRouterAddress = vault.oracleRouter();
        
        BentoUSD bentoUSD = BentoUSD(bentoUSDAddress);
        BentoUSDPlus bentoUSDPlus = BentoUSDPlus(bentoUSDPlusAddress);
        OracleRouter oracle = OracleRouter(oracleRouterAddress);

        // Print basic vault info
        console.log("=== Vault Configuration ===");
        console.log("Vault address:", vaultAddress);
        console.log("BentoUSD address:", bentoUSDAddress);
        console.log("Oracle Router address:", oracleRouterAddress);
        console.log("Governor address:", vault.governor());
        console.log("BentoUSD+ address:", bentoUSDPlusAddress);
        console.log("underlying asset:", bentoUSDPlus.asset());
        console.log("BentoUSD+ name:", IERC20Metadata(bentoUSDPlusAddress).name());
        console.log("BentoUSD+ symbol:", IERC20Metadata(bentoUSDPlusAddress).symbol());
        console.log("BentoUSD+ decimals:", IERC20Metadata(bentoUSDPlusAddress).decimals());
        
        // Print supported assets
        VaultStorage.Asset[] memory vaultAssets = vault.getAssets();
        console.log("\n=== Supported Assets ===");
        for (uint i = 0; i < vaultAssets.length; i++) {
            address asset = vault.allAssets(i);
            VaultStorage.Asset memory assetInfo = vaultAssets[i];
            IERC20Metadata token = IERC20Metadata(asset);
            address ltToken = assetInfo.ltToken;
            
            console.log("\nAsset", i + 1);
            console.log("Name:", token.name());
            console.log("Symbol:", token.symbol());
            console.log("Address:", asset);
            console.log("Decimals:", assetInfo.decimals);
            console.log("Weight:", assetInfo.weight, "%");
            console.log("Strategy:", vault.assetToStrategy(asset));
            console.log("ltToken:", ltToken);
            console.log("ltToken name:", IERC20Metadata(ltToken).name());
            console.log("ltToken symbol:", IERC20Metadata(ltToken).symbol());
            console.log("ltToken decimals:", IERC20Metadata(ltToken).decimals());
            
            // Get asset balance in vault
            uint256 balance = token.balanceOf(vaultAddress);
            console.log("Balance in vault:", balance);
            
            // Get price from oracle
            try oracle.price(asset) returns (uint256 price) {
                console.log("Price (USD):", price);
            } catch {
                console.log("Price: Error getting price");
            }
        }

        // Print BentoUSD info
        console.log("\n=== BentoUSD Info ===");
        console.log("Name:", IERC20Metadata(bentoUSDAddress).name());
        console.log("Symbol:", IERC20Metadata(bentoUSDAddress).symbol());
        console.log("Total Supply:", bentoUSD.totalSupply());
        console.log("Vault Balance:", bentoUSD.balanceOf(vaultAddress));
    }
}