// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {StableMath} from "../utils/StableMath.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {VaultAdmin} from "./VaultAdmin.sol";
import {BentoUSD} from "../BentoUSD.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title VaultCore
 * @notice Core vault implementation for BentoUSD stablecoin system
 * @dev Handles minting, redeeming, and asset allocation operations
 */
contract VaultCore is Initializable, VaultAdmin {
    using SafeERC20 for IERC20;
    using StableMath for uint256;
    uint256 public constant deviationTolerance = 1; // in percentage

    event SwapResult(
        address inputAsset,
        address outputAsset,
        address router,
        uint256 amount
    );

    event AssetAllocated(
        address asset,
        address strategy,
        uint256 amount
    );

    error SwapFailed(string reason);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // === External Functions ===
    
    function initialize(address _governor) public initializer {
        require(_governor != address(0), "Governor cannot be zero address");
        governor = _governor;
    }

    /**
     * @notice Mints BentoUSD tokens in exchange for a single supported asset
     * @param _asset Address of the input asset
     * @param _amount Amount of input asset to deposit
     * @param _minimumBentoUSDAmount Minimum acceptable BentoUSD output
     * @param _routers Array of DEX router addresses for swaps
     * @param _routerData Encoded swap data for each router
     */
    function mint(
        address _asset,
        uint256 _amount,
        uint256 _minimumBentoUSDAmount,
        address[] calldata _routers,
        bytes[] calldata _routerData
    ) external {
        _mint(_asset, _amount, _minimumBentoUSDAmount, _routers, _routerData);
    }

    /**
     * @notice Mints BentoUSD by depositing a proportional basket of all supported assets
     * @param _amount Total USD value to deposit
     * @param _minimumBentoUSDAmount Minimum acceptable BentoUSD output
     */
    function mintBasket(
        uint256 _amount,
        uint256 _minimumBentoUSDAmount
    ) external {
        (uint256[] memory amounts, uint256 totalAmount) = getDepositAssetAmounts(_amount);
        for (uint256 i = 0; i < allAssets.length; i++) {
            address assetAddress = allAssets[i];
            IERC20(assetAddress).safeTransferFrom(msg.sender, address(this), amounts[i]);
        }
        require(
            totalAmount > _minimumBentoUSDAmount,
            string(
                abi.encodePacked(
            "VaultCore: price deviation too high. Total value: ",
            Strings.toString(totalAmount),
            ", Minimum required: ",
                    Strings.toString(_minimumBentoUSDAmount)
                )
            )
        );
        BentoUSD(bentoUSD).mint(msg.sender, totalAmount);
    }

    /**
     * @notice Redeems BentoUSD for liquid staking tokens of supported assets
     * @param _amount Amount of BentoUSD to redeem
     */
    function redeemLTBasket(uint256 _amount) external {
        uint256[] memory ltAmounts = getOutputLTAmounts(_amount);
        BentoUSD(bentoUSD).burn(msg.sender, _amount);
        for (uint256 i = 0; i < allAssets.length; i++) {
            address assetAddress = allAssets[i];
            IERC20(assetAddress).safeTransfer(msg.sender, ltAmounts[i]);
        }
    }

    /**
     * @notice Allocates excess assets in the vault to yield-generating strategies
     * @dev Can only be called by the governor
     */
    function allocate() external onlyGovernor {
        _allocate();
    }

    // === Public View Functions ===

    /**
     * @notice Calculates the required amounts of each asset for a proportional deposit
     * @param desiredAmount Total USD value to be deposited
     * @return Array of asset amounts and total USD value
     */
    function getDepositAssetAmounts(uint256 desiredAmount) public view returns (uint256[] memory, uint256) {
        uint256 numberOfAssets = allAssets.length;
        uint256[] memory relativeWeights = new uint256[](numberOfAssets);
        uint256[] memory amounts = new uint256[](numberOfAssets);
        uint256 totalRelativeWeight = 0;
        for (uint256 i = 0; i < numberOfAssets; i++) {
            address assetAddress = allAssets[i];

            uint256 assetPrice = IOracle(oracleRouter).price(assetAddress);
            if (assetPrice > 1e18) {
                assetPrice = 1e18;
            }
            relativeWeights[i] = assets[assetAddress].weight * assetPrice;
            totalRelativeWeight += relativeWeights[i];
        }
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < numberOfAssets; i++) {
            // we round it upwards to avoid rounding errors detrimental for the protocol
            amounts[i] = (desiredAmount * relativeWeights[i]) / totalRelativeWeight;
            totalAmount += amounts[i];
        }
        return (amounts, totalAmount);
    }

    function getOutputLTAmounts(uint256 inputAmount) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](allAssets.length);
        for (uint256 i = 0; i < allAssets.length; i++) {
            address asset = allAssets[i];
            address ltToken = assets[asset].ltToken;
            uint256 partialInputAmount = (inputAmount * assets[asset].weight) / totalWeight;
            uint256 assetPrice = IOracle(oracleRouter).price(asset);
            if (assetPrice < 1e18) {
                assetPrice = 1e18;
            }
            amounts[i] = IERC4626(ltToken).convertToShares(partialInputAmount / assetPrice);
        }
        return amounts;
    }

    // === Internal Functions ===

    function _mint(
        address _asset,
        uint256 _amount,
        uint256 _minimumBentoUSDAmount,
        address[] calldata _routers,
        bytes[] calldata _routerData
    ) internal virtual {
        require(assets[_asset].isSupported, "Asset is not supported");
        require(_amount > 0, "Amount must be greater than 0");
        require(
            _routerData.length == allAssets.length,
            "Invalid router data length"
        );

        // store total weight into a memory variable to save gas
        uint256 _totalWeight = totalWeight;
        uint256 _allAssetsLength = allAssets.length;

        // store the total value of the basket
        uint256 totalValueOfBasket = 0;
        uint256 allAssetsLength = allAssets.length;
        // we iterate through all assets
        for (uint256 i = 0; i < allAssetsLength; i++) {
            address assetAddress = allAssets[i];
            // we only trade into assets that are not the asset we are depositing
            if (assetAddress != _asset) {
                Asset memory asset = assets[assetAddress];
                // get the balance of the asset before the trade
                uint256 balanceBefore = IERC20(assetAddress).balanceOf(
                    address(this)
                );
                // get asset price from oracle
                uint256 assetPrice = IOracle(oracleRouter).price(assetAddress);
                if (assetPrice > 1e18) {
                    assetPrice = 1e18;
                }
                _swap(_routers[i], _routerData[i]);
                // get the balance of the asset after the trade
                uint256 balanceAfter = IERC20(assetAddress).balanceOf(
                    address(this)
                );
                // get the amount of asset that is not in the balance after the trade
                uint256 outputAmount = balanceAfter - balanceBefore;
                emit SwapResult(
                    _asset,
                    assetAddress,
                    _routers[i],
                    outputAmount
                );
                uint256 expectedOutputAmount = (_amount * asset.weight) /
                    _totalWeight;
                uint256 deviation = (expectedOutputAmount > outputAmount)
                    ? expectedOutputAmount - outputAmount
                    : outputAmount - expectedOutputAmount;
                uint256 deviationPercentage = (deviation * 100) /
                    expectedOutputAmount;
                require(
                    deviationPercentage < deviationTolerance,
                    "VaultCore: deviation from desired weights too high"
                );
                totalValueOfBasket += (outputAmount * assetPrice) / 1e18;
            } else {
                uint256 assetPrice = IOracle(oracleRouter).price(assetAddress);
                totalValueOfBasket += (_amount * assetPrice) / 1e18;
            }
        }

        require(
            totalValueOfBasket > _minimumBentoUSDAmount,
            string(
                abi.encodePacked(
                    "VaultCore: price deviation too high. Total value: ",
                    Strings.toString(totalValueOfBasket),
                    ", Minimum required: ",
                    Strings.toString(_minimumBentoUSDAmount)
                )
            )
        );
        BentoUSD(bentoUSD).mint(msg.sender, totalValueOfBasket);
    }

    function _swap(address _router, bytes calldata _routerData) internal {
        (bool success, bytes memory _data) = _router.call(_routerData);
        if (!success) {
            if (_data.length > 0) revert SwapFailed(string(_data));
            else revert SwapFailed("Unknown reason");
        }
    }

    function _redeemUnderlyingBasket(uint256 _amount) internal {
        uint256 allAssetsLength = allAssets.length;
        for (uint256 i = 0; i < allAssetsLength; i++) {
            address assetAddress = allAssets[i];
            uint256 assetPrice = IOracle(oracleRouter).price(assetAddress);
            if (assetPrice < 1e18) {
                assetPrice = 1e18;
            }
            uint256 amountToRedeem = (_amount *
                assets[assetAddress].weight *
                assetPrice) / (totalWeight * 1e18);
            IERC20(assetAddress).safeTransfer(msg.sender, amountToRedeem);
        }
        BentoUSD(bentoUSD).burn(msg.sender, _amount);
    }

    function _redeemWithWaitingPeriod(uint256 _amount) internal {
        revert("VaultCore: redeemWithWaitingPeriod is not implemented");
    }

    function _allocate() internal virtual {
        uint256 allAssetsLength = allAssets.length;
        for (uint256 i = 0; i < allAssetsLength; ++i) {
            IERC20 asset = IERC20(allAssets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));
            uint256 minimalAmount = minimalAmountInVault[address(asset)];
            if (assetBalance < minimalAmount) continue;
            // Multiply the balance by the vault buffer modifier and truncate
            // to the scale of the asset decimals
            uint256 allocateAmount = assetBalance - minimalAmount;

            address depositStrategyAddr = assetToStrategy[address(asset)];

            if (depositStrategyAddr != address(0) && allocateAmount > 0) {
                IStrategy strategy = IStrategy(depositStrategyAddr);
                // Transfer asset to Strategy and call deposit method to
                // mint or take required action
                asset.safeTransfer(address(strategy), allocateAmount);
                strategy.deposit(allocateAmount);
                emit AssetAllocated(
                    address(asset),
                    depositStrategyAddr,
                    allocateAmount
                );
            }
        }
    }

    // === Internal Pure Functions ===

    function normalizeDecimals(uint8 assetDecimals, uint256 amount) internal pure returns (uint256) {
        if (assetDecimals < 18) {
            return amount / 10 ** (18 - assetDecimals);
        } else if (assetDecimals > 18) {
            return amount * 10 ** (assetDecimals - 18);
        }
        return amount;
    }

    function getTotalValue() public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < allAssets.length; i++) {
            address asset = allAssets[i];
            // Get direct asset balance
            uint256 balance = IERC20(asset).balanceOf(address(this));
            
            // Get LT token balance and convert to underlying
            address ltToken = assets[asset].ltToken;
            uint256 ltBalance = IERC20(ltToken).balanceOf(address(this));
            uint256 underlyingBalance = IERC4626(ltToken).convertToAssets(ltBalance);
            
            // Get total balance (direct + underlying from LT)
            uint256 totalBalance = balance + underlyingBalance;
            
            // Multiply by price to get USD value
            uint256 assetPrice = IOracle(oracleRouter).price(asset);
            totalValue += (totalBalance * assetPrice) / 1e18;
        }
        return totalValue;
    }

    function getTokenToShareRatios() public view returns (uint256[] memory) {
        uint256 allAssetsLength = allAssets.length;
        uint256[] memory ratios = new uint256[](allAssetsLength);
        for (uint256 i = 0; i < allAssetsLength; i++) {
            address vault = assets[allAssets[i]].ltToken;
            ratios[i] = IERC4626(vault).convertToShares(1e18);
        }
        return ratios;
    }
}
