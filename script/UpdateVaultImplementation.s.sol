// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/vault/VaultCore.sol";
import "../src/UpgradableProxy.sol";


contract UpdateVaultImplementation is Script {
    function run() external {
        bool deployNewImplementation = false;
        bool setNewImplementation = false;
        bool transferImplementation = true;
        uint256 deployerPrivateKey = vm.envUint("BentoSepoliaDeployerPrivateKey");
        address owner = vm.addr(deployerPrivateKey);
        
        // Contract addresses
        address proxyAddress = 0x2DC4Da4832604f886A81120dB11108057f6D6BAf;
        UpgradableProxy proxy = UpgradableProxy(payable(proxyAddress));
        
        console.log("current operator address:", owner);
        console.log("Current implementation:", proxy.implementation());
        console.log("New implementation:", proxy.newImplementation());
        console.log("Current proxy owner:", proxy.proxyOwner());
        
        // Check if there's an ongoing upgrade
        address newImplementation = 0x68A610FA4766952c91A35BbeDf3f6A02065eCacB;
        vm.startBroadcast(deployerPrivateKey);

        if (deployNewImplementation) {
            // deploy new implementation
            VaultCore newImplementationContract = new VaultCore();
            console.log("New implementation deployed at:", address(newImplementationContract));
            newImplementation = address(newImplementationContract);
        }

        if (setNewImplementation) {
            //set new implementation
            console.log("Setting new implementation to:", newImplementation);
            proxy.setNewImplementation(newImplementation);

            console.log("New implementation set, timelock started");
            console.log("Timelock ends at:", proxy.timelock());
            console.log("Current time:", block.timestamp);
        }

        if (transferImplementation) {
            // transfer implementation
            proxy.transferImplementation();
            console.log("Implementation transferred to:", proxy.implementation());
        }
        vm.stopBroadcast();
    }
} 