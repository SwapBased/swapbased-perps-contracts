// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/MintableBaseToken.sol";

contract BnBASE is MintableBaseToken {
    constructor() public MintableBaseToken("Bonus BASE", "bnBASE", 0) {}

    function id() external pure returns (string memory _name) {
        return "bnBASE";
    }
}
