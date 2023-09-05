// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../access/Governable.sol";
import "../peripherals/interfaces/ITimelock.sol";

contract RewardManager is Governable {
    bool public isInitialized;

    ITimelock public timelock;
    address public rewardRouter;

    address public blpManager;

    address public stakedBaseTracker;
    address public bonusBaseTracker;
    address public feeBaseTracker;

    address public feeBlpTracker;
    address public stakedBlpTracker;

    address public stakedBaseDistributor;
    address public stakedBlpDistributor;

    address public esBase;
    address public bnBase;

    address public baseVester;
    address public blpVester;

    function initialize(
        ITimelock _timelock,
        address _rewardRouter,
        address _blpManager,
        address _stakedBaseTracker,
        address _bonusBaseTracker,
        address _feeBaseTracker,
        address _feeBlpTracker,
        address _stakedBlpTracker,
        address _stakedBaseDistributor,
        address _stakedBlpDistributor,
        address _esBase,
        address _bnBase,
        address _baseVester,
        address _blpVester
    ) external onlyGov {
        require(!isInitialized, "RewardManager: already initialized");
        isInitialized = true;

        timelock = _timelock;
        rewardRouter = _rewardRouter;

        blpManager = _blpManager;

        stakedBaseTracker = _stakedBaseTracker;
        bonusBaseTracker = _bonusBaseTracker;
        feeBaseTracker = _feeBaseTracker;

        feeBlpTracker = _feeBlpTracker;
        stakedBlpTracker = _stakedBlpTracker;

        stakedBaseDistributor = _stakedBaseDistributor;
        stakedBlpDistributor = _stakedBlpDistributor;

        esBase = _esBase;
        bnBase = _bnBase;

        baseVester = _baseVester;
        blpVester = _blpVester;
    }

    // function updateEsBaseHandlers() external onlyGov {
    //     timelock.managedSetHandler(esBase, rewardRouter, true);

    //     timelock.managedSetHandler(esBase, stakedBaseDistributor, true);
    //     timelock.managedSetHandler(esBase, stakedBlpDistributor, true);

    //     timelock.managedSetHandler(esBase, stakedBaseTracker, true);
    //     timelock.managedSetHandler(esBase, stakedBlpTracker, true);

    //     timelock.managedSetHandler(esBase, baseVester, true);
    //     timelock.managedSetHandler(esBase, blpVester, true);
    // }

    // function enableRewardRouter() external onlyGov {
    //     timelock.managedSetHandler(blpManager, rewardRouter, true);

    //     timelock.managedSetHandler(stakedBaseTracker, rewardRouter, true);
    //     timelock.managedSetHandler(bonusBaseTracker, rewardRouter, true);
    //     timelock.managedSetHandler(feeBaseTracker, rewardRouter, true);

    //     timelock.managedSetHandler(feeBlpTracker, rewardRouter, true);
    //     timelock.managedSetHandler(stakedBlpTracker, rewardRouter, true);

    //     timelock.managedSetHandler(esBase, rewardRouter, true);

    //     timelock.managedSetMinter(bnBase, rewardRouter, true);

    //     timelock.managedSetMinter(esBase, baseVester, true);
    //     timelock.managedSetMinter(esBase, blpVester, true);

    //     timelock.managedSetHandler(baseVester, rewardRouter, true);
    //     timelock.managedSetHandler(blpVester, rewardRouter, true);

    //     timelock.managedSetHandler(feeBaseTracker, baseVester, true);
    //     timelock.managedSetHandler(stakedBlpTracker, blpVester, true);
    // }
}
