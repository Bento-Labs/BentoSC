// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Addresses {
    // Mainnet addresses
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant sDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant sDAI_USD_FEED = 0x73366a099E198b828E6023232990e16406673607;
    address constant DAI_USD_FEED = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address constant USDC_USD_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address constant USDT_USD_FEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;

    // Sepolia addresses
    address constant SEPOLIA_DAI = 0x4F12d4e3FE59Ad54f7e9704B71467eB368b2F498;
    address constant SEPOLIA_USDC = 0xC98F51755976811c1D71d895DA2A73b46Dfbc918;
    address constant SEPOLIA_USDT = 0x5Fd341Ba92C4F6e6B7778Ba303D8B1EBd36A9cA0;
    address constant SEPOLIA_USDe = 0x63c9C938be90E0692840E310e917aF1De40e314B;

    // Sepolia2 addresses
    address constant SEPOLIA2_DAI = 0x6982508145454ce325dDbe47a25D4eC6D4BaF8d8;
    address constant SEPOLIA2_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant SEPOLIA2_USDT = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;

    // Helper function to get mainnet token addresses
    function getMainnetTokens() internal pure returns (address[] memory) {
        address[] memory tokens = new address[](4);
        tokens[0] = DAI;
        tokens[1] = sDAI;
        tokens[2] = USDC;
        tokens[3] = USDT;
        return tokens;
    }

    // Helper function to get sepolia token addresses
    function getSepoliaTokens() internal pure returns (address[] memory) {
        address[] memory tokens = new address[](4);
        tokens[0] = SEPOLIA_DAI;
        tokens[1] = SEPOLIA_USDC;
        tokens[2] = SEPOLIA_USDT;
        tokens[3] = SEPOLIA_USDe;
        return tokens;
    }

    // Helper function to get sepolia2 token addresses
    function getSepolia2Tokens() internal pure returns (address[] memory) {
        address[] memory tokens = new address[](3);
        tokens[0] = SEPOLIA2_DAI;
        tokens[1] = SEPOLIA2_USDC;
        tokens[2] = SEPOLIA2_USDT;
        return tokens;
    }
} 