// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/MintableBaseToken.sol";

contract BLP is MintableBaseToken {
    constructor() public MintableBaseToken("BASE LP", "BLP", 0) {}

    function id() external pure returns (string memory _name) {
        return "BLP";
    }
}
