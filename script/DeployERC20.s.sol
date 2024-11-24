// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {CustomERC20} from "../src/utils/CustomERC20.sol";
import {console} from "forge-std/console.sol";


contract DeployERC20 is Script {
    function run() external {
        // Load the private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("BentoSepoliaDeployerPrivateKey");
        address owner = vm.addr(deployerPrivateKey);
        
        console.log("Deploying with address:", owner);
        console.log("deployer balance is:", owner.balance, "wei");

        string memory name = "test USDe";
        string memory symbol = "USDe";

        console.log("Deploying Custom name:", name, "symbol:", symbol);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Custom USDT
        CustomERC20 usdt = new CustomERC20(name, symbol);
        console.log("test USDT deployed to:", address(usdt));

        vm.stopBroadcast();
    }
}