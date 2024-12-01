// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IBentoBoxV1} from "../interfaces/IBentoBoxV1.sol";

contract VaultStorage {
    // === Constants ===
    uint256 public constant WAITING_PERIOD = 3 days;

    // === State Variables ===
    
    // Addresses & Core Components
    address public governor;
    IBentoBoxV1 public immutable bentoBox;
    IERC20 public immutable bentoUSD;
    IERC20[] public assets;

    // Configuration
    uint256[] public relativeWeights;
    uint256 public totalRelativeWeight;
    uint256 public lastAllocation;
    
    // Redemption Related
    mapping(address => uint256) public redemptionQueue;
    mapping(address => uint256) public redemptionQueueStart;

    // === Events ===
    event Mint(address indexed sender, uint256 amount);
    event Redeem(address indexed sender, uint256 amount);
    event AllocationUpdated();
    event RedemptionRequested(address indexed sender, uint256 amount);
    event RedemptionProcessed(address indexed sender, uint256 amount);

    // === External View Functions ===
    
    function getAssets() external view returns (IERC20[] memory) {
        return assets;
    }

    function getRelativeWeights() external view returns (uint256[] memory) {
        return relativeWeights;
    }

    // === Constructor ===
    
    constructor(address _bentoBox, address _bentoUSD) {
        require(_bentoBox != address(0), "BentoBox cannot be zero address");
        require(_bentoUSD != address(0), "BentoUSD cannot be zero address");
        bentoBox = IBentoBoxV1(_bentoBox);
        bentoUSD = IERC20(_bentoUSD);
    }
}
