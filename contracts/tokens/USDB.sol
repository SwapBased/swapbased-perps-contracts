// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IUSDB.sol";
import "./YieldToken.sol";

contract USDB is YieldToken, IUSDB {
    mapping(address => bool) public vaults;

    modifier onlyVault() {
        require(vaults[msg.sender], "USDB: forbidden");
        _;
    }

    constructor(address _vault) public YieldToken("USD Base", "USDB", 0) {
        vaults[_vault] = true;
    }

    function addVault(address _vault) external override onlyGov {
        vaults[_vault] = true;
    }

    function removeVault(address _vault) external override onlyGov {
        vaults[_vault] = false;
    }

    function mint(address _account, uint256 _amount) external override onlyVault {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyVault {
        _burn(_account, _amount);
    }
}
