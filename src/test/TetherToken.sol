/**
 *Submitted for verification at Etherscan.io on 2017-11-28
*/

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

contract BlackList is Ownable {
    mapping(address => bool) public isBlackListed;
    
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    
    constructor(address initialOwner) Ownable(initialOwner) {}
    
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }
    
    function addBlackList(address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
}

contract Pausable {
    bool public paused = false;
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }
    
    function _pause() internal virtual {
        paused = true;
    }
    
    function _unpause() internal virtual {
        paused = false;
    }
}

// Mock USDT token that mimics the behavior of the real USDT token
contract TetherToken is Pausable, BlackList {
    string public name;
    string public symbol;
    uint8 public decimals;
    address public upgradedAddress;
    bool public deprecated;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deprecate(address newAddress);
    
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4, "Short call data");
        _;
    }
    
    constructor(
        uint256 initialSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) BlackList(msg.sender) {
        _totalSupply = initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _balances[msg.sender] = initialSupply;
        deprecated = false;
    }
    
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }
    
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    // Mimics USDT's non-standard transfer behavior (no return value)
    function transfer(address to, uint256 value) 
        public 
        whenNotPaused 
        onlyPayloadSize(2 * 32)
    {
        require(!isBlackListed[msg.sender], "Sender is blacklisted");
        require(to != address(0), "Transfer to zero address");
        require(_balances[msg.sender] >= value, "Insufficient balance");

        console.log("Transfer from %s to %s of %s", msg.sender, to, value);
        
        _balances[msg.sender] -= value;
        _balances[to] += value;
        emit Transfer(msg.sender, to, value);
    }
    
    // Mimics USDT's non-standard approve behavior (no return value)
    function approve(address spender, uint256 value) 
        public 
        onlyPayloadSize(2 * 32)
    {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    // Mimics USDT's non-standard transferFrom behavior (no return value)
    function transferFrom(
        address from, 
        address to, 
        uint256 value
    ) 
        public 
        whenNotPaused 
        onlyPayloadSize(3 * 32)
    {
        require(!isBlackListed[from], "Sender is blacklisted");
        require(to != address(0), "Transfer to zero address");
        require(_balances[from] >= value, "Insufficient balance");
        require(_allowances[from][msg.sender] >= value, "Insufficient allowance");
        
        _balances[from] -= value;
        _balances[to] += value;
        _allowances[from][msg.sender] -= value;
        emit Transfer(from, to, value);
    }
    
    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }
}