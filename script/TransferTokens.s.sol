// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Addresses} from "./Addresses.sol";

contract TransferTokens is Script {
    using SafeERC20 for IERC20;

    function run() external {
        // Load private key and tokens from environment
        uint256 deployerPrivateKey = vm.envUint("BentoSepoliaDeployerPrivateKey");
        address sender = vm.addr(deployerPrivateKey);
        
        // Parse arrays from environment strings (comma-separated)
        address[4] memory tokens = [Addresses.SEPOLIA_DAI, Addresses.SEPOLIA_USDC, Addresses.SEPOLIA_USDT, Addresses.SEPOLIA_USDe];
        address[2] memory recipients = [0x5118470D402d840a0091c6574F7D8ee5C32e0551, 0x3cA5f5caa07b47c5c6c85afC684A482d2cE9a5e4];
        uint256 amount = 10000e18;

        vm.startBroadcast(deployerPrivateKey);

        for(uint i = 0; i < tokens.length; i++) {
            for(uint j = 0; j < recipients.length; j++) {
                address token = tokens[i];
                address recipient = recipients[j];
                
                uint256 initialBalance = IERC20(token).balanceOf(sender);
                console.log("Token:", token);
                console.log("Recipient:", recipient);
                console.log("Initial balance:", initialBalance);
                
                require(initialBalance >= amount, "Insufficient balance");
                
                IERC20(token).safeTransfer(recipient, amount);
                vm.txWait(); // Wait for the transfer transaction to be mined
  
                uint256 finalBalance = IERC20(token).balanceOf(sender);
                uint256 recipientBalance = IERC20(token).balanceOf(recipient);
                
                console.log("Final sender balance:", finalBalance);
                console.log("Recipient balance:", recipientBalance);
                console.log("---");
            }
        }

        vm.stopBroadcast();
    }
} 