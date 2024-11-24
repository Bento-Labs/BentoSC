// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/vault/VaultCore.sol";
import "../src/BentoUSD.sol";
import "../src/OracleRouter.sol";
import "../src/strategy/Generalized4626Strategy.sol";
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

    // external protocol vault or share token
    address constant sDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address constant sUSDC = 0xBEEF01735c132Ada46AA9aA4c54623cAA92A64CB;
    address constant sUSDT = 0xbEef047a543E45807105E51A8BBEFCc5950fcfBa;
    address constant sUSDe = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;

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

        console.log("VaultCore proxy address:", address(proxy));
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

        assertApproxEqRel(usdcDeposited * 1e12, mintAmount * 25 / 100, 0.01e18, "USDC deposit proportion incorrect");
        assertApproxEqRel(daiDeposited, mintAmount * 25 / 100, 0.01e18, "DAI deposit proportion incorrect");
        assertApproxEqRel(usdtDeposited * 1e12, mintAmount * 25 / 100, 0.01e18, "USDT deposit proportion incorrect");
        assertApproxEqRel(usdeDeposited, mintAmount * 25 / 100, 0.01e18, "USDe deposit proportion incorrect");

        vm.stopPrank();
    }

    function testSetupStrategies() public {
        // check that the underlying asset stored inside share token contract is correct
        assertEq(IERC4626(sUSDC).asset(), USDC, "sUSDC underlying asset incorrect");
        assertEq(IERC4626(sDAI).asset(), DAI, "sDAI underlying asset incorrect");
        assertEq(IERC4626(sUSDT).asset(), USDT, "sUSDT underlying asset incorrect");
        assertEq(IERC4626(sUSDe).asset(), USDE, "sUSDe underlying asset incorrect");

        // Deploy strategies for each asset
        Generalized4626Strategy usdcStrategy = new Generalized4626Strategy(
            USDC,                // asset token
            sUSDC,               // sUSDC address
            address(vault)       // admin
        );
        
        Generalized4626Strategy daiStrategy = new Generalized4626Strategy(
            DAI,                // asset token
            sDAI,               // sDAI address
            address(vault)       // admin
        );
        
        Generalized4626Strategy usdtStrategy = new Generalized4626Strategy(
            USDT,               // asset token
            sUSDT,               // sUSDT address
            address(vault)       // admin
        );
        
        Generalized4626Strategy usdeStrategy = new Generalized4626Strategy(
            USDE,               // asset token
            sUSDe,               // sUSDe address
            address(vault)       // admin
        );

        // Set strategies in vault
        vm.startPrank(owner);
        vault.setStrategy(USDC, address(usdcStrategy));
        vault.setStrategy(DAI, address(daiStrategy));
        vault.setStrategy(USDT, address(usdtStrategy));
        vault.setStrategy(USDE, address(usdeStrategy));
        vm.stopPrank();

        // Verify strategies are set correctly
        assertEq(vault.assetToStrategy(USDC), address(usdcStrategy), "USDC strategy not set correctly");
        assertEq(vault.assetToStrategy(DAI), address(daiStrategy), "DAI strategy not set correctly");
        assertEq(vault.assetToStrategy(USDT), address(usdtStrategy), "USDT strategy not set correctly");
        assertEq(vault.assetToStrategy(USDE), address(usdeStrategy), "USDE strategy not set correctly");

        
    }

    function testAllocateToStrategies() public {
        // First setup the strategies
        testSetupStrategies();
        
        // Then mint a basket to get assets into the vault
        uint256 mintAmount = 1000e18; // 1000 BentoUSD
        uint256 minAmount = 990e18;   // 0.99% slippage

        vm.startPrank(user);
        vault.mintBasket(mintAmount, minAmount);
        vm.stopPrank();

        // Get vault balances before allocation
        uint256 vaultUSDCBefore = IERC20(USDC).balanceOf(address(vault));
        uint256 vaultDAIBefore = IERC20(DAI).balanceOf(address(vault));
        uint256 vaultUSDTBefore = IERC20(USDT).balanceOf(address(vault));
        uint256 vaultUSDeBefore = IERC20(USDE).balanceOf(address(vault));

        console.log("Vault USDC balance before allocation:", vaultUSDCBefore / 1e6);
        console.log("Vault DAI balance before allocation:", vaultDAIBefore / 1e18);
        console.log("Vault USDT balance before allocation:", vaultUSDTBefore / 1e6);
        console.log("Vault USDe balance before allocation:", vaultUSDeBefore / 1e18);

        // Allocate assets to strategies
        vm.startPrank(owner);
        vault.allocate();
        vm.stopPrank();

        // Get vault balances after allocation
        uint256 vaultUSDCAfter = IERC20(USDC).balanceOf(address(vault));
        uint256 vaultDAIAfter = IERC20(DAI).balanceOf(address(vault));
        uint256 vaultUSDTAfter = IERC20(USDT).balanceOf(address(vault));
        uint256 vaultUSDeAfter = IERC20(USDE).balanceOf(address(vault));

        // Get strategy share token balances
        uint256 vaultUSDCShares = IERC20(sUSDC).balanceOf(address(vault));
        uint256 vaultDAIShares = IERC20(sDAI).balanceOf(address(vault));
        uint256 vaultUSDTShares = IERC20(sUSDT).balanceOf(address(vault));
        uint256 vaultUSDeShares = IERC20(sUSDe).balanceOf(address(vault));

        // Verify vault balances are now 0 (all allocated)
        assertEq(vaultUSDCAfter, 0, "USDC not fully allocated");
        assertEq(vaultDAIAfter, 0, "DAI not fully allocated");
        assertEq(vaultUSDTAfter, 0, "USDT not fully allocated");
        assertEq(vaultUSDeAfter, 0, "USDe not fully allocated");


        console.log("Vault USDC shares:", vaultUSDCShares);
        console.log("Vault DAI shares:", vaultDAIShares);
        console.log("Vault USDT shares:", vaultUSDTShares);
        console.log("Vault USDe shares:", vaultUSDeShares);

        console.log(IERC4626(sUSDC).previewDeposit(10e6));

        // Verify strategies received shares
        assertGt(vaultUSDCShares, 0, "Vault didn't receive USDC shares");
        assertGt(vaultDAIShares, 0, "Vault didn't receive DAI shares");
        assertGt(vaultUSDTShares, 0, "Vault didn't receive USDT shares");
        assertGt(vaultUSDeShares, 0, "Vault didn't receive USDe shares");

    }

    
}
