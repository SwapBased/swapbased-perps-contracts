// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./RewardTracker.sol";

contract StakedBaseTracker is RewardTracker {
    constructor() public RewardTracker("Staked BASE", "sBASE") {}
}

contract BonusBaseTracker is RewardTracker {
    constructor() public RewardTracker("Staked + Bonus BASE", "sbBASE") {}
}

contract FeeBaseTracker is RewardTracker {
    constructor() public RewardTracker("Staked + Bonus + Fee BASE", "sbfBASE") {}
}

contract StakedBlpTracker is RewardTracker {
    constructor() public RewardTracker("Fee + Staked BLP", "fsBLP") {}
}

contract FeeBlpTracker is RewardTracker {
    constructor() public RewardTracker("Fee BLP", "fBLP") {}
}
