// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/vault/VaultCore.sol";
import "../src/BentoUSD.sol";
import "../src/OracleRouter.sol";
import "../src/UpgradableProxy.sol";

contract DeployVault is Script {
    function run() external {
        bool deployNewBentoUSDFlag = true;
        bool deployNewOracleRouterFlag = true;
        bool deployNewVaultFlag = true;
        bool setBentoUSDVaultFlag = true;
        uint256 deployerPrivateKey = vm.envUint("BentoSepoliaDeployerPrivateKey");
        address owner = vm.addr(deployerPrivateKey);
        
        console.log("deployer address is:", owner);
        
        // Check owner's ETH balance
        uint256 ownerBalance = owner.balance;
        console.log("deployer balance is:", ownerBalance, "wei");
        
        vm.startBroadcast(deployerPrivateKey);

        BentoUSD bentoUSD = BentoUSD(0x6ae08082387AaBcA74830054B1f3ba8a0571F9c6);
        if (deployNewBentoUSDFlag) {
            // Deploy BentoUSD implementation
            bentoUSD= new BentoUSD(
                "BentoUSD", // name
                "BUSD",     // symbol
                owner,         
                owner
            );
            console.log(" new BentoUSD deployed at:", address(bentoUSD));
        } else {
            console.log("BentoUSD already deployed at:", address(bentoUSD));
        }

        // Deploy OracleRouter
        OracleRouter oracle = OracleRouter(0x8f86bFc69a9A8bfEceB81f02B8A34327a785b58b);
        if (deployNewOracleRouterFlag) {
            oracle = new OracleRouter(owner);
            console.log(" new OracleRouter deployed at:", address(oracle));
        } else {
            console.log("OracleRouter already deployed at:", address(oracle));
        }

        // Deploy VaultCore implementation
        UpgradableProxy vaultProxy = UpgradableProxy(payable(0x8FDE145B1289a99C6B15f363309d3cc9276c0b16));
        VaultCore vaultImpl = VaultCore(0xB001e62bA3c8B4797aC1D6950d723b627737a92E);
        if (deployNewVaultFlag) {
            vaultImpl = new VaultCore();
            console.log(" new VaultCore implementation deployed at:", address(vaultImpl));
            // Deploy VaultCore proxy
            bytes memory vaultData = abi.encodeWithSelector(
                VaultCore.initialize.selector,
                owner,                    // owner
                address(bentoUSD),      // bentoUSD
                address(oracle)           // oracle router
            );
            vaultProxy = new UpgradableProxy(
                owner,
                address(vaultImpl),
                vaultData,
                10,
                true
            );
            console.log("VaultCore proxy deployed at:", address(vaultProxy));
        } else {
            console.log("VaultCore implementation already deployed at:", address(vaultImpl));
            console.log("VaultCore proxy already deployed at:", address(vaultProxy));
        }

        


        if (setBentoUSDVaultFlag) {
            // Set vault in BentoUSD
            bentoUSD.setBentoUSDVault(address(vaultProxy));
            console.log("Vault in BentoUSD set to:", address(vaultProxy));
        } else {
            console.log("Vault in BentoUSD already set to:", address(vaultProxy));
        }

        vm.stopBroadcast();

    }
} 