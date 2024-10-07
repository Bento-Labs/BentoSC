// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/OracleRouter.sol";
// Remove or comment out this line if the interface is already imported in OracleRouter.sol
// import "../src/interfaces/AggregatorV3Interface.sol";

contract OracleRouterTest is Test {
    OracleRouter public oracleRouter;
    address public owner;
    address public addr1;

    // Mainnet addresses
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDC_USD_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address constant DAI_USD_FEED = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address constant USDT_USD_FEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;

    // Fork block number
    uint256 constant FORK_BLOCK_NUMBER = 20911501;

    function setUp() public {
        // Fork Ethereum mainnet at the specified block number
        vm.createSelectFork("mainnet", FORK_BLOCK_NUMBER);

        owner = address(this);
        addr1 = address(0x1);
        
        oracleRouter = new OracleRouter(owner);

        // Add feeds for testing
        oracleRouter.addFeed(USDC, USDC_USD_FEED, 86400); // 1 day staleness
        oracleRouter.addFeed(DAI, DAI_USD_FEED, 3600); // 1 hour staleness
        oracleRouter.addFeed(USDT, USDT_USD_FEED, 86400); // 1 day staleness
    }

    function testOwnership() public {
        assertEq(oracleRouter.owner(), owner);
    }

    function testOnlyOwnerCanAddFeed() public {
        // Owner should be able to add a feed
        oracleRouter.addFeed(USDC, USDC_USD_FEED, 86400);

        // Non-owner should not be able to add a feed
        vm.prank(addr1);
        vm.expectRevert("OwnableUnauthorizedAccount");
        oracleRouter.addFeed(DAI, DAI_USD_FEED, 3600);
    }

    function testPrices() public {
        uint256 usdcPrice = oracleRouter.price(USDC);
        uint256 daiPrice = oracleRouter.price(DAI);
        uint256 usdtPrice = oracleRouter.price(USDT);

        console.log("USDC price:", usdcPrice);
        console.log("DAI price:", daiPrice);
        console.log("USDT price:", usdtPrice);

        // Check USDC price
        assertTrue(usdcPrice > 0);
        assertTrue(usdcPrice <= 1.1e18); // MAX_DRIFT
        assertTrue(usdcPrice >= 0.9e18); // MIN_DRIFT

        // Check DAI price
        assertTrue(daiPrice > 0);
        assertTrue(daiPrice <= 1.1e18); // MAX_DRIFT
        assertTrue(daiPrice >= 0.9e18); // MIN_DRIFT

        // Check USDT price
        assertTrue(usdtPrice > 0);
        assertTrue(usdtPrice <= 1.1e18); // MAX_DRIFT
        assertTrue(usdtPrice >= 0.9e18); // MIN_DRIFT
    }

    function testUnsupportedAsset() public {
        vm.expectRevert("Asset not available");
        oracleRouter.price(address(0));
    }

    function testStalePrices() public {
        // Increase time by more than the max staleness
        skip(86401); // 1 day + 1 second

        vm.expectRevert("Oracle price too old");
        oracleRouter.price(USDC);
    }
}
