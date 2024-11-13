// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUSDT} from "../src/interfaces/IUSDT.sol";
import "../src/test/TetherToken.sol";

contract TetherTokenTest is Test {
    using SafeERC20 for IERC20;

    TetherToken public tether;
    IERC20 public usdtERC20;
    IUSDT public usdtCustom;
    
    address public user1;
    address public user2;
    uint256 public constant INITIAL_SUPPLY = 1000000e6; // 1M USDT

    function setUp() public {
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy TetherToken with initial supply
        tether = new TetherToken(
            INITIAL_SUPPLY,
            "Tether USD",
            "USDT",
            6
        );
        
        // Create interfaces
        usdtERC20 = IERC20(address(tether));
        usdtCustom = IUSDT(address(tether));

        // Transfer some tokens to user1
        vm.startPrank(address(this));
        tether.transfer(user1, 1000e6); // 1000 USDT
        vm.stopPrank();
    }

    function testTransferMethods() public {
        vm.startPrank(user1);
        uint256 transferAmount = 100e6; // 100 USDT

        uint256 balanceUser1Before = usdtERC20.balanceOf(user1);
        uint256 balanceUser2Before = usdtERC20.balanceOf(user2);
        console.log("Balance of user1 before transfer:", balanceUser1Before);
        console.log("Balance of user2 before transfer:", balanceUser2Before);
        
        // Test transfer using IERC20
        console.log("\nTesting transfer using IERC20...");
        usdtERC20.safeTransfer(user2, transferAmount);
        /* try usdtERC20.safeTransfer(user2, transferAmount) {
            console.log("Transfer succeeded");
        } catch Error(string memory reason) {
            console.log("Transfer failed with Error:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Transfer failed with low level error:", vm.toString(lowLevelData));
        } */

        // Test transfer using IUSDT
        console.log("\nTesting transfer using IUSDT...");
        try usdtCustom.transfer(user2, transferAmount) {
            console.log("Transfer succeeded");
        } catch Error(string memory reason) {
            console.log("Transfer failed with Error:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Transfer failed with low level error:", vm.toString(lowLevelData));
        }


        vm.stopPrank();
    }
}
