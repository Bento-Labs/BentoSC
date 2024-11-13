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

    /**
     * @notice Initialize the VaultCore contract
     * @param _governor Address of the governor
     */
    function initialize(
        address _governor
    ) public initializer {
        require(_governor != address(0), "Governor cannot be zero address");
        governor = _governor;
    }

    /**
     * @notice Deposit a supported asset and mint BentoUSD.
     * @param _asset Address of the asset being deposited
     * @param _amount Amount of the asset being deposited
     * @param _minimumBentoUSDAmount Minimum BentoUSD to mint
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

    /**
     * @notice Mint BentoUSD by depositing a proportional basket of all supported assets
     * @dev This function mints BentoUSD by accepting deposits of all supported assets in their target weights
     * @param _amount The total amount of BentoUSD to mint
     * @param _minimumBentoUSDAmount The minimum amount of BentoUSD to receive (slippage protection)
     */
    function mintBasket(
        uint256 _amount,
        uint256 _minimumBentoUSDAmount
    ) external {
        uint256 totalValueOfBasket = 0;
        for (uint256 i = 0; i < allAssets.length; i++) {
            address assetAddress = allAssets[i];
            uint8 assetDecimals = assets[assetAddress].decimals;
            // amounttoDeposit is assumed to have 18 decimals
            uint256 amountToDeposit = (_amount * assets[assetAddress].weight) /
                totalWeight;
            uint256 amountToDepositWithDecimals = amountToDeposit;
            // we need to shift the decimals places
            if (assetDecimals < 18) {
                amountToDepositWithDecimals = amountToDeposit / 10 ** (18 - assetDecimals);
            } else if (assetDecimals > 18) {
                amountToDepositWithDecimals = amountToDeposit * 10 ** (assetDecimals - 18);
            }
            IERC20(assetAddress).safeTransferFrom(msg.sender, address(this), amountToDepositWithDecimals);

            uint256 assetPrice = IOracle(oracleRouter).price(assetAddress);
            if (assetPrice > 1e18) {
                assetPrice = 1e18;
            }
            totalValueOfBasket += (amountToDeposit * assetPrice) / 1e18;
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

    function _redeemLtBasket(uint256 _amount) internal {
        uint256 allAssetsLength = allAssets.length;

        for (uint256 i = 0; i < allAssetsLength; i++) {
            address assetAddress = allAssets[i];
            address ltToken = assets[assetAddress].ltToken;
            uint256 ltTokenPrice = IOracle(oracleRouter).price(ltToken);
            if (ltTokenPrice < 1e18) {
                ltTokenPrice = 1e18;
            }
            uint256 amountToRedeem = (_amount *
                assets[assetAddress].weight *
                ltTokenPrice) / (totalWeight * 1e18);
            IERC20(ltToken).safeTransfer(msg.sender, amountToRedeem);
        }
        BentoUSD(bentoUSD).burn(msg.sender, _amount);
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

    /**
     * @dev Allocate unallocated funds on Vault to strategies.
     **/
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
                strategy.deposit(address(asset), allocateAmount);
                emit AssetAllocated(
                    address(asset),
                    depositStrategyAddr,
                    allocateAmount
                );
            }
        }
    }
}
