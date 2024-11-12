// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

/**
 * @title ERC4626Strategy
 * @notice Strategy for interacting with ERC4626 vaults
 */
contract ERC4626Strategy is IStrategy {
    using SafeERC20 for IERC20;

    IERC4626 public immutable vault;
    IERC20 public immutable asset;
    address[] public rewardTokens;

    constructor(address _vault) {
        vault = IERC4626(_vault);
        asset = IERC20(vault.asset());
    }

    /**
     * @notice Deposits assets into the ERC4626 vault
     * @param _asset Asset to deposit
     * @param _amount Amount of assets to deposit
     */
    function deposit(address _asset, uint256 _amount) external override {
        require(_asset == address(asset), "Unsupported asset");
        require(_amount > 0, "Amount must be greater than 0");

        // Transfer asset from sender
        asset.safeTransferFrom(msg.sender, address(this), _amount);
        
        // Approve vault to spend asset
        asset.approve(address(vault), _amount);
        
        // Deposit into vault
        vault.deposit(_amount, address(this));
    }

    /**
     * @notice Deposit all supported assets into the vault
     */
    function depositAll() external override {
        uint256 balance = asset.balanceOf(address(this));
        if (balance > 0) {
            asset.approve(address(vault), balance);
            vault.deposit(balance, address(this));
        }
    }

    /**
     * @notice Withdraws assets from the ERC4626 vault
     * @param _recipient Address to receive the withdrawn assets
     * @param _asset Asset to withdraw
     * @param _amount Amount of assets to withdraw
     */
    function withdraw(
        address _recipient,
        address _asset,
        uint256 _amount
    ) external override {
        require(_asset == address(asset), "Unsupported asset");
        require(_amount > 0, "Amount must be greater than 0");

        // Convert amount to shares
        uint256 shares = vault.convertToShares(_amount);
        
        // Withdraw from vault
        vault.withdraw(_amount, _recipient, address(this));
    }

    /**
     * @notice Withdraw all assets from the vault
     */
    function withdrawAll() external override {
        uint256 shares = vault.balanceOf(address(this));
        if (shares > 0) {
            vault.redeem(shares, msg.sender, address(this));
        }
    }

    /**
     * @notice Check balance of an asset
     * @param _asset Asset to check balance for
     */
    function checkBalance(address _asset) external view override returns (uint256) {
        require(_asset == address(asset), "Unsupported asset");
        uint256 shares = vault.balanceOf(address(this));
        return vault.convertToAssets(shares);
    }

    /**
     * @notice Check if asset is supported
     * @param _asset Asset to check
     */
    function supportsAsset(address _asset) external view override returns (bool) {
        return _asset == address(asset);
    }

    /**
     * @notice Collect reward tokens if any
     */
    function collectRewardTokens() external override {
        // Most ERC4626 vaults don't have explicit reward tokens
        // Override this if the specific vault implementation has rewards
    }

    /**
     * @notice Get reward token addresses
     */
    function getRewardTokenAddresses() external view override returns (address[] memory) {
        return rewardTokens;
    }
}
