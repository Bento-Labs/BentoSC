// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/OracleRouter.sol";
import "../src/interfaces/chainlink/AggregatorV3Interface.sol";
import "../src/utils/sDAIFeed.sol";
import "../src/utils/ERC4626Feed.sol";
import {console} from "forge-std/console.sol";


contract OracleRouterTest is Test {
    OracleRouter public oracleRouter;
    address public owner;
    address public addr1;

    // Mainnet addresses
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDE = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    address constant USDC_USD_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address constant DAI_USD_FEED = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address constant USDT_USD_FEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address constant USDE_USD_FEED = 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961;

    // Fork block number
    uint256 constant FORK_BLOCK_NUMBER = 20911501;

    // Add sDAI and its feed address
    address constant SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address constant SDAI_USD_FEED = 0xb9E6DBFa4De19CCed908BcbFe1d015190678AB5f;
    // address of Morpho ERC4626 vault for USDC and USDT
    address constant STEAKHOUSE_USDC = 0xBEEF01735c132Ada46AA9aA4c54623cAA92A64CB;
    address constant STEAKHOUSE_USDT = 0xbEef047a543E45807105E51A8BBEFCc5950fcfBa;
    // address of Ethena USDe ERC4626 vault
    address constant sUSDe = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;

    sDAIFeed public sDAIFeedContract;
    ERC4626Feed public steakhouseUSDCFeed;
    ERC4626Feed public steakhouseUSDTFeed;
    ERC4626Feed public sUSDeFeed;

    error OwnableUnauthorizedAccount(address account);


    function setUp() public {
        // Fork Ethereum mainnet at the specified block number
        vm.createSelectFork(vm.envString("MainnetAlchemyAPI"), FORK_BLOCK_NUMBER);

        owner = address(this);
        addr1 = address(0x1);
        
        oracleRouter = new OracleRouter(owner);

        // Deploy sDAIFeed contract
        sDAIFeedContract = new sDAIFeed(SDAI_USD_FEED);

        // Deploy ERC4626Feed contract for STEAKHOUSE_USDC
        steakhouseUSDCFeed = new ERC4626Feed(
            address(oracleRouter),
            STEAKHOUSE_USDC,
            "STEAKHOUSE_USDC Feed"
        );

        // Deploy ERC4626Feed contract for STEAKHOUSE_USDT
        steakhouseUSDTFeed = new ERC4626Feed(
            address(oracleRouter),
            STEAKHOUSE_USDT,
            "STEAKHOUSE_USDT Feed"
        );

        // Deploy sUSDeFeed contract
        sUSDeFeed = new ERC4626Feed(
            address(oracleRouter),
            sUSDe,
            "sUSDe Feed"
        );

        // Add feeds for testing
        uint8 usdcDecimals = AggregatorV3Interface(USDC_USD_FEED).decimals();
        uint8 daiDecimals = AggregatorV3Interface(DAI_USD_FEED).decimals();
        uint8 usdtDecimals = AggregatorV3Interface(USDT_USD_FEED).decimals();
        uint8 usdeDecimals = AggregatorV3Interface(USDE_USD_FEED).decimals();

        oracleRouter.addFeed(USDC, USDC_USD_FEED, 86400, usdcDecimals); // 1 day staleness
        oracleRouter.addFeed(DAI, DAI_USD_FEED, 3600, daiDecimals); // 1 hour staleness
        oracleRouter.addFeed(USDT, USDT_USD_FEED, 86400, usdtDecimals); // 1 day staleness
        oracleRouter.addFeed(USDE, USDE_USD_FEED, 86400, usdeDecimals); // 1 day staleness
        // Add sDAI feed
        uint8 sDAIDecimals = AggregatorV3Interface(address(sDAIFeedContract)).decimals();
        oracleRouter.addFeed(SDAI, address(sDAIFeedContract), 86400, sDAIDecimals); // 1 day staleness

        // Add STEAKHOUSE_USDC feed
        uint8 steakhouseUSDCDecimals = steakhouseUSDCFeed.decimals();
        oracleRouter.addFeed(STEAKHOUSE_USDC, address(steakhouseUSDCFeed), 86400, steakhouseUSDCDecimals); // 1 day staleness

        // Add STEAKHOUSE_USDT feed
        uint8 steakhouseUSDTDecimals = steakhouseUSDTFeed.decimals();
        oracleRouter.addFeed(STEAKHOUSE_USDT, address(steakhouseUSDTFeed), 86400, steakhouseUSDTDecimals); // 1 day staleness

        // Add sUSDe feed
        uint8 sUSDeDecimals = sUSDeFeed.decimals();
        oracleRouter.addFeed(sUSDe, address(sUSDeFeed), 86400, sUSDeDecimals); // 1 day staleness
    }

    function testOwnership() public view {
        assertEq(oracleRouter.owner(), owner);
    }

    function testOnlyOwnerCanAddFeed() public {
        uint8 decimals = AggregatorV3Interface(USDC_USD_FEED).decimals();
        // Owner should be able to add a feed
        oracleRouter.addFeed(USDC, USDC_USD_FEED, 86400, decimals);

        // Non-owner should not be able to add a feed
        vm.prank(addr1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, addr1));
        oracleRouter.addFeed(DAI, DAI_USD_FEED, 3600, decimals);
    }

    function testUSDCPrice() public view {
        uint256 usdcPrice = oracleRouter.price(USDC);
        console.log("USDC price:", usdcPrice);

        assertTrue(usdcPrice > 0);
        assertTrue(usdcPrice <= 1.1e18); // MAX_DRIFT
        assertTrue(usdcPrice >= 0.9e18); // MIN_DRIFT
    }

    function testDAIPrice() public view {
        uint256 daiPrice = oracleRouter.price(DAI);
        console.log("DAI price:", daiPrice);

        assertTrue(daiPrice > 0);
        assertTrue(daiPrice <= 1.1e18); // MAX_DRIFT
        assertTrue(daiPrice >= 0.9e18); // MIN_DRIFT
    }

    function testUSDTPrice() public view {
        uint256 usdtPrice = oracleRouter.price(USDT);
        console.log("USDT price:", usdtPrice);

        assertTrue(usdtPrice > 0);
        assertTrue(usdtPrice <= 1.1e18); // MAX_DRIFT
        assertTrue(usdtPrice >= 0.9e18); // MIN_DRIFT
    }

    function testUSDEPrice() public view {
        uint256 usdePrice = oracleRouter.price(USDE);
        console.log("USDe price:", usdePrice);

        assertTrue(usdePrice > 0);
        assertTrue(usdePrice <= 1.1e18); // MAX_DRIFT
        assertTrue(usdePrice >= 0.9e18); // MIN_DRIFT
    }

    function testSDAIPrice() public view {
        uint256 sDAIPrice = oracleRouter.price(SDAI);
        console.log("sDAI price:", sDAIPrice);

        assertTrue(sDAIPrice > 0);
        // Add more specific assertions for sDAI if needed
    }

    function testSteakhouseUSDCPrice() public view {
        uint256 steakhouseUSDCPrice = oracleRouter.price(STEAKHOUSE_USDC);
        console.log("STEAKHOUSE_USDC price:", steakhouseUSDCPrice);

        assertTrue(steakhouseUSDCPrice > 0);
        // Note: The price range for an ERC4626 token might be different from stablecoins
        // Adjust these assertions based on the expected behavior of STEAKHOUSE_USDC
        assertTrue(steakhouseUSDCPrice <= 1.5e18); // Adjust MAX_DRIFT as needed
        assertTrue(steakhouseUSDCPrice >= 0.5e18); // Adjust MIN_DRIFT as needed
    }

    function testSUSDePrice() public view {
        uint256 sUSDePrice = oracleRouter.price(sUSDe);
        console.log("sUSDe price:", sUSDePrice);

        assertTrue(sUSDePrice > 0);
        // Note: The price range for an ERC4626 token might be different from stablecoins
        assertTrue(sUSDePrice <= 1.5e18); // Adjust MAX_DRIFT as needed
        assertTrue(sUSDePrice >= 0.5e18); // Adjust MIN_DRIFT as needed
    }

    function testSteakhouseUSDTPrice() public view {
        uint256 steakhouseUSDTPrice = oracleRouter.price(STEAKHOUSE_USDT);
        console.log("STEAKHOUSE_USDT price:", steakhouseUSDTPrice);

        assertTrue(steakhouseUSDTPrice > 0);
        // Note: The price range for an ERC4626 token might be different from stablecoins
        // Adjust these assertions based on the expected behavior of STEAKHOUSE_USDT
        assertTrue(steakhouseUSDTPrice <= 1.5e18); // Adjust MAX_DRIFT as needed
        assertTrue(steakhouseUSDTPrice >= 0.5e18); // Adjust MIN_DRIFT as needed
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
