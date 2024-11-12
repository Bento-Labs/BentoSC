// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/vault/VaultCore.sol";
import "../src/BentoUSD.sol";
import "../src/OracleRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {IUSDT} from "../src/interfaces/IUSDT.sol"; // Import the IUSDT interface

contract VaultCoreTest is Test {
    using SafeERC20 for IERC20;

    VaultCore public implementation;
    VaultCore public vault;
    BentoUSD public bentoUSD;
    OracleRouter public oracleRouter;
    ProxyAdmin public proxyAdmin;
    
    address public owner;
    address public user;

    // Mainnet addresses (same as in OracleRouterTest)
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    // Price feed addresses
    address constant USDC_USD_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address constant DAI_USD_FEED = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address constant USDT_USD_FEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;

    function setUp() public {
        // Fork mainnet
        vm.createSelectFork(vm.envString("MainnetAlchemyAPI"), 20911501);
        console.log("Fork created");
        
        owner = address(this);
        user = address(0x1);
        console.log("Addresses set - owner:", owner);
        
        // Deploy contracts
        oracleRouter = new OracleRouter(owner);
        console.log("OracleRouter deployed");
        
        bentoUSD = new BentoUSD("BentoUSD", "BUSD", address(0), owner);
        console.log("BentoUSD deployed");
        
        // Deploy implementation
        implementation = new VaultCore();
        console.log("VaultCore implementation deployed");

        // Deploy ProxyAdmin
        proxyAdmin = new ProxyAdmin(owner);
        console.log("ProxyAdmin deployed");

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            VaultCore.initialize.selector,
            owner
        );

        // Deploy proxy
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );
        console.log("Proxy deployed");

        // Create vault interface
        vault = VaultCore(address(proxy));
        console.log("Vault interface created");

        // Setup vault
        vault.setBentoUSD(address(bentoUSD));
        vault.setOracleRouter(address(oracleRouter));

        bentoUSD.setBentoUSDVault(address(vault));

        console.log("Adding price feeds...");
        // Add price feeds
        oracleRouter.addFeed(USDC, USDC_USD_FEED, 86400, 8);
        oracleRouter.addFeed(DAI, DAI_USD_FEED, 86400, 8);
        oracleRouter.addFeed(USDT, USDT_USD_FEED, 86400, 8);

        console.log("Setting assets in vault...");
        // Add assets to vault with equal weights
        vault.setAsset(USDC, 6, 33, address(0));  // 33% weight
        vault.setAsset(DAI, 18, 33, address(0));  // 33% weight
        vault.setAsset(USDT, 6, 34, address(0));  // 34% weight

        console.log("Dealing tokens to user...");
        deal(USDC, user, 1000e6);
        deal(DAI, user, 1000e18);
        deal(USDT, user, 1000e6);

        console.log("Approving vault to spend user's tokens...");
        vm.startPrank(user);
        console.log("Approving USDC...");
        IERC20(USDC).approve(address(vault), type(uint256).max);
        console.log("Approving DAI...");
        IERC20(DAI).approve(address(vault), type(uint256).max);
        console.log("Approving USDT...");
        IUSDT(USDT).approve(address(vault), type(uint256).max);
        vm.stopPrank();

        console.log("Vault setup complete");
    }

    function testMintBasket() public {
        uint256 mintAmount = 1000e18; // 1000 BentoUSD
        uint256 minAmount = 990e18;   // 0.99% slippage

        vm.startPrank(user);
        
        // Get initial balances
        uint256 initialUSDC = IERC20(USDC).balanceOf(user);
        uint256 initialDAI = IERC20(DAI).balanceOf(user);
        uint256 initialUSDT = IERC20(USDT).balanceOf(user);
        uint256 initialBentoUSD = bentoUSD.balanceOf(user);

        // Mint basket
        vault.mintBasket(mintAmount, minAmount);

        // Check final balances
        uint256 finalUSDC = IERC20(USDC).balanceOf(user);
        uint256 finalDAI = IERC20(DAI).balanceOf(user);
        uint256 finalUSDT = IERC20(USDT).balanceOf(user);
        uint256 finalBentoUSD = bentoUSD.balanceOf(user);

        // Verify BentoUSD minted
        assertGt(finalBentoUSD, initialBentoUSD, "Should have minted BentoUSD");
        assertApproxEqRel(finalBentoUSD - initialBentoUSD, mintAmount, 0.01e18, "Should have minted correct amount");

        // Verify proportional deposits
        assertLt(finalUSDC, initialUSDC, "Should have deposited USDC");
        assertLt(finalDAI, initialDAI, "Should have deposited DAI");
        assertLt(finalUSDT, initialUSDT, "Should have deposited USDT");

        // Verify deposit proportions (33/33/34 split)
        uint256 usdcDeposited = initialUSDC - finalUSDC;
        uint256 daiDeposited = initialDAI - finalDAI;
        uint256 usdtDeposited = initialUSDT - finalUSDT;

        assertApproxEqRel(usdcDeposited * 3e6, mintAmount * 33e6 / 100, 0.01e18, "USDC deposit proportion incorrect");
        assertApproxEqRel(daiDeposited * 1e18, mintAmount * 33e18 / 100, 0.01e18, "DAI deposit proportion incorrect");
        assertApproxEqRel(usdtDeposited * 3e6, mintAmount * 34e6 / 100, 0.01e18, "USDT deposit proportion incorrect");

        vm.stopPrank();
    }

    function testMintBasketWithSlippageProtection() public {
        uint256 mintAmount = 1000e18;
        uint256 minAmount = 1001e18; // Set minimum higher than possible

        vm.startPrank(user);
        vm.expectRevert("VaultCore: price deviation too high");
        vault.mintBasket(mintAmount, minAmount);
        vm.stopPrank();
    }
}
