// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardRouter {
    function stakeBase(uint256 _amount) external;
    
    function stakeEsBase(uint256 _amount) external;

    function unstakeBase(uint256 _amount) external;

    function unstakeEsBase(uint256 _amount) external;

    function signalTransfer(address _receiver) external;

    function compound() external;

    function handleRewards(
        bool _shouldClaimBase,
        bool _shouldStakeBase,
        bool _shouldClaimEsBase,
        bool _shouldStakeEsBase,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external returns (uint256 amountOut);
}
