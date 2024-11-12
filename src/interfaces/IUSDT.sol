// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// we need to use this interface because USDT functions are not compatible with standard ERC20 regarding returned values
interface IUSDT {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}