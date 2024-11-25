// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/vault/VaultCore.sol";
import "../src/UpgradableProxy.sol";

contract UpdateVaultImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("BentoSepoliaDeployerPrivateKey");
        address owner = vm.addr(deployerPrivateKey);
        
        // Contract addresses
        address proxyAddress = 0x8FDE145B1289a99C6B15f363309d3cc9276c0b16;
        UpgradableProxy proxy = UpgradableProxy(payable(proxyAddress));
        
        console.log("Current implementation:", proxy.implementation());
        console.log("Current proxy owner:", proxy.proxyOwner());
        
        vm.startBroadcast(deployerPrivateKey);

        // check if we already have a new implementation if not deploy a new one
        address newImplementationAddress = address(0);
        if (newImplementationAddress == address(0)) {
            VaultCore newImplementation = new VaultCore();
            newImplementationAddress = address(newImplementation);
            console.log("New implementation deployed at:", newImplementationAddress);
        } 

        // Set new implementation in proxy
        proxy.setNewImplementation(address(newImplementation));
        console.log("New implementation set, timelock started");
        console.log("Timelock ends at:", proxy.timelock());

        // Note: You'll need to call transferImplementation() after the timelock period
        // using a separate script or transaction

        vm.stopBroadcast();
    }
} 