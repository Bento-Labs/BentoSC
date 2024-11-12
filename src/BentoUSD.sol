// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OFT} from "solidity-examples/contracts/token/oft/v1/OFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BentoUSD is Ownable, OFT {
    address public bentoUSDVault;
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint) Ownable(_delegate) {
        // Any additional initialization logic
    }

    function mint(address _to, uint256 _amount) public {
        require(msg.sender == bentoUSDVault || msg.sender == owner(), "BentoUSD: only bentoUSDVault or owner can mint");
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function setBentoUSDVault(address _bentoUSDVault) public onlyOwner {
        bentoUSDVault = _bentoUSDVault;
    }
}
