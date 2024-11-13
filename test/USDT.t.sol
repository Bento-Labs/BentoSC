// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUSDT} from "../src/interfaces/IUSDT.sol";

contract USDTTest is Test {
    using SafeERC20 for IERC20;

    IERC20 public usdt;
    IUSDT public usdt2;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    address public user1;
    address public user2;
    uint256 public constant INITIAL_BALANCE = 1000e6; // 1000 USDT

    function setUp() public {
        // Fork mainnet
        vm.createSelectFork(vm.envString("MainnetAlchemyAPI"), 20911501);
        
        usdt = IERC20(USDT);
        usdt2 = IUSDT(USDT);
        user1 = address(0x11);
        user2 = address(0x2);

        // Give user1 some USDT
        deal(USDT, user1, INITIAL_BALANCE);
    }

    function testTransferMethods() public {
        vm.startPrank(user1);
        console.log("User1 address:", user1);
        uint256 transferAmount = 100e6; // 100 USDT

        uint256 balanceUser1Before = usdt.balanceOf(user1);
        console.log("Balance of user1 before transfer:", balanceUser1Before);
        
        // Check if USDT is paused
        (bool success, bytes memory data) = USDT.staticcall(abi.encodeWithSignature("paused()"));
        if (success) {
            bool isPaused = abi.decode(data, (bool));
            console.log("USDT paused status:", isPaused);
        }

        // Test transfer using IERC20
        /* usdt.safeTransfer(user2, transferAmount); */
        /* console.log("Testing transfer using IERC20...");
        try usdt.safeTransfer(user2, transferAmount) {
            console.log("Transfer succeeded");
        } catch Error(string memory reason) {
            console.log("Transfer failed with Error:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Transfer failed with low level error:", vm.toString(lowLevelData));
        }
 */
        // Test transfer using IUSDT
        console.log("\nTesting transfer using IUSDT...");
        // First check if user is blacklisted
        (bool success2, bytes memory data2) = USDT.staticcall(
            abi.encodeWithSignature("isBlackListed(address)", user1)
        );
        if (success2) {
            bool isBlacklisted = abi.decode(data2, (bool));
            console.log("User1 blacklist status:", isBlacklisted);
        }

        try usdt2.transfer(user2, transferAmount) {
            console.log("Transfer succeeded");
        } catch Error(string memory reason) {
            console.log("Transfer failed with Error:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Transfer failed with low level error:", vm.toString(lowLevelData));
        }

        vm.stopPrank();
    }
}
