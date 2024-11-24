// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {console} from "forge-std/console.sol";

contract CustomERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000_000_000 * 10**decimals()); // Mint 1 trillion tokens
    }
}

contract DeployERC20 is Script {
    function run() external {
        // Load the private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("BentoSepoliaDeployerPrivateKey");
        address owner = vm.addr(deployerPrivateKey);
        
        console.log("Deploying with address:", owner);
        console.log("deployer balance is:", owner.balance, "wei");

        string memory name = "test USDT";
        string memory symbol = "USDT";

        console.log("Deploying Custom name:", name, "symbol:", symbol);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Custom USDT
        CustomERC20 usdt = new CustomERC20(name, symbol);
        console.log("test USDT deployed to:", address(usdt));

        vm.stopBroadcast();
    }
}