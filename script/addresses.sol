// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Addresses {
    // Mainnet addresses
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant sDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant sUSDC = 0xBEEF01735c132Ada46AA9aA4c54623cAA92A64CB;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant sUSDT = 0xbEef047a543E45807105E51A8BBEFCc5950fcfBa;
    address public constant USDe = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    address public constant sUSDe = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;

    address public constant sDAI_USD_FEED = 0x73366a099E198b828E6023232990e16406673607;
    address public constant DAI_USD_FEED = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;
    address public constant USDC_USD_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address public constant USDT_USD_FEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address public constant USDe_USD_FEED = 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961;

    // Sepolia addresses
    address public constant SEPOLIA_DAI = 0x4F12d4e3FE59Ad54f7e9704B71467eB368b2F498;
    address public constant SEPOLIA_USDC = 0xC98F51755976811c1D71d895DA2A73b46Dfbc918;
    address public constant SEPOLIA_USDT = 0x5Fd341Ba92C4F6e6B7778Ba303D8B1EBd36A9cA0;
    address public constant SEPOLIA_USDe = 0x63c9C938be90E0692840E310e917aF1De40e314B;
    address public constant SEPOLIA_DAI_USD_FEED = 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19;
    address public constant SEPOLIA_USDC_USD_FEED = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;
    address public constant SEPOLIA_USDT_USD_FEED = 0x55ec7c3ed0d7CB5DF4d3d8bfEd2ecaf28b4638fb;
    address public constant SEPOLIA_USDe_USD_FEED = 0x6f7be09227d98Ce1Df812d5Bc745c0c775507E92;

    // Sepolia2 addresses
    address public constant SEPOLIA2_DAI = 0x6982508145454ce325dDbe47a25D4eC6D4BaF8d8;
    address public constant SEPOLIA2_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address public constant SEPOLIA2_USDT = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;

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