// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/vault/VaultCore.sol";
import "../src/BentoUSD.sol";
import "../src/OracleRouter.sol";
import "../src/UpgradableProxy.sol";
import "../src/BentoUSDPlus.sol";

contract DeployVault is Script {
    function run() external {
        bool deployNewBentoUSDFlag = false;
        bool deployNewOracleRouterFlag = false;
        bool deployNewVaultFlag = false;
        bool setBentoUSDVaultFlag = false;
        bool deployBentoUSDPlusFlag = true;
        uint256 deployerPrivateKey = vm.envUint("BentoSepoliaDeployerPrivateKey");
        address owner = vm.addr(deployerPrivateKey);
        
        console.log("deployer address is:", owner);
        
        // Check owner's ETH balance
        uint256 ownerBalance = owner.balance;
        console.log("deployer balance is:", ownerBalance, "wei");
        
        vm.startBroadcast(deployerPrivateKey);

        BentoUSD bentoUSD = BentoUSD(0xfeD4BB1f4Ce7C74e23BE2B968E2962431726d4f3);
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
        OracleRouter oracle = OracleRouter(0x8274713D419da3531DfAe1e9ed89d6F9c359cc4d);
        if (deployNewOracleRouterFlag) {
            oracle = new OracleRouter(owner);
            console.log(" new OracleRouter deployed at:", address(oracle));
        } else {
            console.log("OracleRouter already deployed at:", address(oracle));
        }

        // Deploy VaultCore implementation
        UpgradableProxy vaultProxy = UpgradableProxy(payable(0x2DC4Da4832604f886A81120dB11108057f6D6BAf));
        VaultCore vaultImpl = VaultCore(0xB001e62bA3c8B4797aC1D6950d723b627737a92E);
        if (deployNewVaultFlag) {
            vaultImpl = new VaultCore();
            console.log(" new VaultCore implementation deployed at:", address(vaultImpl));
            // Deploy VaultCore proxy
            bytes memory vaultData = abi.encodeWithSelector(
                VaultCore.initialize.selector,
                owner     // owner, governor
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

        if (deployBentoUSDPlusFlag) {
            // Deploy BentoUSDPlus
            BentoUSDPlus bentoUSDPlus = new BentoUSDPlus(
                IERC20(bentoUSD)
            );
            console.log("BentoUSDPlus deployed at:", address(bentoUSDPlus));
        }

        vm.stopBroadcast();

    }
} 