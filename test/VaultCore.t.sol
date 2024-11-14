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


contract VaultCoreTest is Test {
    using SafeERC20 for IERC20;

    VaultCore public implementation;
    VaultCore public vault;
    BentoUSD public bentoUSD;
    OracleRouter public oracleRouter;
    ProxyAdmin public proxyAdmin;
    
    address public owner;
    address public user;

    // Mainnet addresses
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDE = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    
    // Price feed addresses
    address constant USDC_USD_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address constant DAI_USD_FEED = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address constant USDT_USD_FEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address constant USDE_USD_FEED = 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961;

    function setUp() public {
        // Fork mainnet
        vm.createSelectFork(vm.envString("MainnetAlchemyAPI"), 20911501);
        console.log("Fork created");
        
        owner = address(this);
        user = address(0x11);
        console.log("Addresses set - owner:", owner);
        
        // Deploy contracts
        oracleRouter = new OracleRouter(owner);
        console.log("OracleRouter deployed");
        
        bentoUSD = new BentoUSD("BentoUSD", "BUSD", address(0), owner);
        console.log("BentoUSD deployed");
        
        implementation = new VaultCore();
        console.log("VaultCore implementation deployed");

        proxyAdmin = new ProxyAdmin(owner);
        console.log("ProxyAdmin deployed");

        bytes memory initData = abi.encodeWithSelector(
            VaultCore.initialize.selector,
            owner
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );
        console.log("Proxy deployed");

        vault = VaultCore(address(proxy));
        console.log("Vault interface created");

        // Setup vault
        vault.setBentoUSD(address(bentoUSD));
        vault.setOracleRouter(address(oracleRouter));

        bentoUSD.setBentoUSDVault(address(vault));

        console.log("Adding price feeds...");
        oracleRouter.addFeed(USDC, USDC_USD_FEED, 86400, 8);
        oracleRouter.addFeed(DAI, DAI_USD_FEED, 86400, 8);
        oracleRouter.addFeed(USDT, USDT_USD_FEED, 86400, 8);
        oracleRouter.addFeed(USDE, USDE_USD_FEED, 86400, 8);

        console.log("Setting assets in vault...");
        vault.setAsset(USDC, 6, 25, address(0));   // 25% weight
        vault.setAsset(DAI, 18, 25, address(0));   // 25% weight
        vault.setAsset(USDT, 6, 25, address(0));   // 25% weight
        vault.setAsset(USDE, 18, 25, address(0));  // 25% weight

        console.log("Dealing tokens to user...");
        deal(USDC, user, 1000e6);
        deal(DAI, user, 1000e18);
        deal(USDT, user, 1000e6);
        deal(USDE, user, 1000e18);

        console.log("Approving vault to spend user's tokens...");
        vm.startPrank(user);
        IERC20(USDC).safeIncreaseAllowance(address(vault), type(uint256).max);
        IERC20(DAI).safeIncreaseAllowance(address(vault), type(uint256).max);
        IERC20(USDT).safeIncreaseAllowance(address(vault), type(uint256).max);
        IERC20(USDE).safeIncreaseAllowance(address(vault), type(uint256).max);
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
        uint256 initialUSDe = IERC20(USDE).balanceOf(user);
        uint256 initialBentoUSD = bentoUSD.balanceOf(user);

        console.log("Minting basket of value %s", mintAmount);
        vault.mintBasket(mintAmount, minAmount);

        // Check final balances
        uint256 finalUSDC = IERC20(USDC).balanceOf(user);
        uint256 finalDAI = IERC20(DAI).balanceOf(user);
        uint256 finalUSDT = IERC20(USDT).balanceOf(user);
        uint256 finalUSDe = IERC20(USDE).balanceOf(user);
        uint256 finalBentoUSD = bentoUSD.balanceOf(user);
        uint256 BentoUSDMinted = finalBentoUSD - initialBentoUSD;
        console.log("BentoUSD minted: %s", BentoUSDMinted / 1e18);

        // Verify BentoUSD minted
        assertGt(finalBentoUSD, initialBentoUSD, "Should have minted BentoUSD");
        assertApproxEqRel(BentoUSDMinted, mintAmount, 0.01e18, "Should have minted correct amount");

        // Verify proportional deposits
        assertLt(finalUSDC, initialUSDC, "Should have deposited USDC");
        assertLt(finalDAI, initialDAI, "Should have deposited DAI");
        assertLt(finalUSDT, initialUSDT, "Should have deposited USDT");
        assertLt(finalUSDe, initialUSDe, "Should have deposited USDe");

        // Verify deposit proportions (25/25/25/25 split)
        uint256 usdcDeposited = initialUSDC - finalUSDC;
        uint256 daiDeposited = initialDAI - finalDAI;
        uint256 usdtDeposited = initialUSDT - finalUSDT;
        uint256 usdeDeposited = initialUSDe - finalUSDe;
        
        console.log("USDC deposited: %s", usdcDeposited / 1e6);
        console.log("DAI deposited: %s", daiDeposited / 1e18);
        console.log("USDT deposited: %s", usdtDeposited / 1e6);
        console.log("USDe deposited: %s", usdeDeposited / 1e18);

        assertApproxEqRel(usdcDeposited * 1e12, mintAmount * 25e18 / 100, 0.01e18, "USDC deposit proportion incorrect");
        assertApproxEqRel(daiDeposited, mintAmount * 25 / 100, 0.01e18, "DAI deposit proportion incorrect");
        assertApproxEqRel(usdtDeposited * 1e12, mintAmount * 25e18 / 100, 0.01e18, "USDT deposit proportion incorrect");
        assertApproxEqRel(usdeDeposited, mintAmount * 25 / 100, 0.01e18, "USDe deposit proportion incorrect");

        vm.stopPrank();
    }
}
