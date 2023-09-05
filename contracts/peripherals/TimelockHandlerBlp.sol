// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../core/interfaces/IVaultUtils.sol";
import "./interfaces/timelockhandler/ITimelock.sol";

contract TimelockHandler {
    using SafeMath for uint256;

    address public admin;
    address public tokenManager;
    ITimelock public timelockContract;

    mapping (address => bool) public isHandler; // missing set functions
    mapping (address => bool) public isKeeper; // missing set functions

    uint256 public ratioFeesCollectedPrimary; // 100 = 10%
    address public feesCollector1;
    address public feesCollector2;
    address public vault;
    address[] public tokens;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock: forbidden");
        _;
    }

    modifier onlyHandlerAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyKeeperAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender] || isKeeper[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "Timelock: forbidden");
        _;
    }

    constructor(
        address _admin,
        address _tokenManager,
        ITimelock _timelockContract
    ) public {
        admin = _admin;
        tokenManager = _tokenManager;
        timelockContract = _timelockContract;
    }

    function setAdmin(address _admin) external onlyTokenManager {
        ITimelock(timelockContract).setAdmin(_admin);
    }

    function setExternalAdmin(address _target, address _admin) external onlyAdmin {
        ITimelock(timelockContract).setExternalAdmin(_target, _admin);
    }

    function setContractHandler(address _handler, bool _isActive) external onlyAdmin {
        ITimelock(timelockContract).setContractHandler(_handler, _isActive);
    }

    function setKeeper(address _keeper, bool _isActive) external onlyAdmin {
        ITimelock(timelockContract).setKeeper(_keeper, _isActive);
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        ITimelock(timelockContract).setBuffer(_buffer);
    }

    function setMaxLeverage(address _vault, uint256 _maxLeverage) external onlyAdmin {
        ITimelock(timelockContract).setMaxLeverage(_vault, _maxLeverage);
    }

    function setFundingRate(address _vault, uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setFundingRate(_vault, _fundingInterval, _fundingRateFactor, _stableFundingRateFactor);
    }

    function setShouldToggleIsLeverageEnabled(bool _shouldToggleIsLeverageEnabled) external onlyHandlerAndAbove {
        ITimelock(timelockContract).setShouldToggleIsLeverageEnabled(_shouldToggleIsLeverageEnabled);
    }

    function setMarginFeeBasisPoints(uint256 _marginFeeBasisPoints, uint256 _maxMarginFeeBasisPoints) external onlyHandlerAndAbove {
        ITimelock(timelockContract).setMarginFeeBasisPoints(_marginFeeBasisPoints, _maxMarginFeeBasisPoints);
    }

    function setSwapFees(
        address _vault,
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints
    ) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setSwapFees(_vault, _taxBasisPoints, _stableTaxBasisPoints, _mintBurnFeeBasisPoints, _swapFeeBasisPoints, _stableSwapFeeBasisPoints);
    }

    // assign _marginFeeBasisPoints to this.marginFeeBasisPoints
    // because enableLeverage would update Vault.marginFeeBasisPoints to this.marginFeeBasisPoints
    // and disableLeverage would reset the Vault.marginFeeBasisPoints to this.maxMarginFeeBasisPoints
    function setFees(
        address _vault,
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setFees(_vault, _taxBasisPoints, _stableTaxBasisPoints, _mintBurnFeeBasisPoints, _swapFeeBasisPoints, _stableSwapFeeBasisPoints, _marginFeeBasisPoints, _liquidationFeeUsd, _minProfitTime, _hasDynamicFees);
    }

    function enableLeverage(address _vault) external onlyHandlerAndAbove {
        ITimelock(timelockContract).enableLeverage(_vault);
    }

    function disableLeverage(address _vault) external onlyHandlerAndAbove {
        ITimelock(timelockContract).disableLeverage(_vault);
    }

    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external onlyHandlerAndAbove {
        ITimelock(timelockContract).setIsLeverageEnabled(_vault, _isLeverageEnabled);
    }

    function setTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdbAmount,
        uint256 _bufferAmount,
        uint256 _usdbAmount
    ) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setTokenConfig(_vault, _token, _tokenWeight, _minProfitBps, _maxUsdbAmount, _bufferAmount, _usdbAmount);
    }

    function setUsdbAmounts(address _vault, address[] memory _tokens, uint256[] memory _usdbAmounts) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setUsdbAmounts(_vault, _tokens, _usdbAmounts);
    }

    function updateUsdbSupply(uint256 usdbAmount) external onlyKeeperAndAbove {
        ITimelock(timelockContract).updateUsdbSupply(usdbAmount);
    }

    function setBlpCooldownDuration(uint256 _cooldownDuration) external onlyAdmin {
        ITimelock(timelockContract).setBlpCooldownDuration(_cooldownDuration);
    }

    function setMaxGlobalShortSize(address _vault, address _token, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).setMaxGlobalShortSize(_vault, _token, _amount);
    }

    function removeAdmin(address _token, address _account) external onlyAdmin {
        ITimelock(timelockContract).removeAdmin(_token, _account);
    }

    function setIsSwapEnabled(address _vault, bool _isSwapEnabled) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setIsSwapEnabled(_vault, _isSwapEnabled);
    }

    function setTier(address _referralStorage, uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setTier(_referralStorage, _tierId, _totalRebate, _discountShare);
    }

    function setReferrerTier(address _referralStorage, address _referrer, uint256 _tierId) external onlyKeeperAndAbove {
        ITimelock(timelockContract).setReferrerTier(_referralStorage, _referrer, _tierId);
    }

    function govSetCodeOwner(address _referralStorage, bytes32 _code, address _newAccount) external onlyKeeperAndAbove {
        ITimelock(timelockContract).govSetCodeOwner(_referralStorage, _code, _newAccount);
    }

    function setVaultUtils(address _vault, IVaultUtils _vaultUtils) external onlyAdmin {
        ITimelock(timelockContract).setVaultUtils(_vault, _vaultUtils);
    }

    function setMaxGasPrice(address _vault, uint256 _maxGasPrice) external onlyAdmin {
        ITimelock(timelockContract).setMaxGasPrice(_vault, _maxGasPrice);
    }

    function withdrawFees(address _vault, address _token, address _receiver) external onlyAdmin {
        ITimelock(timelockContract).withdrawFees(_vault, _token, _receiver);
    }

    function batchWithdrawFees(address _vault, address[] memory _tokens) external onlyKeeperAndAbove {
        ITimelock(timelockContract).batchWithdrawFees(_vault, _tokens);
    }

    function setInPrivateLiquidationMode(address _vault, bool _inPrivateLiquidationMode) external onlyAdmin {
        ITimelock(timelockContract).setInPrivateLiquidationMode(_vault, _inPrivateLiquidationMode);
    }

    function setLiquidator(address _vault, address _liquidator, bool _isActive) external onlyAdmin {
        ITimelock(timelockContract).setLiquidator(_vault, _liquidator, _isActive);
    }

    function setInPrivateTransferMode(address _token, bool _inPrivateTransferMode) external onlyAdmin {
        ITimelock(timelockContract).setInPrivateTransferMode(_token, _inPrivateTransferMode);
    }

    function batchSetBonusRewards(address _vester, address[] memory _accounts, uint256[] memory _amounts) external onlyKeeperAndAbove {
        ITimelock(timelockContract).batchSetBonusRewards(_vester, _accounts, _amounts);
    }

    function transferIn(address _sender, address _token, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).transferIn(_sender, _token, _amount);
    }

    function signalApprove(address _token, address _spender, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).signalApprove(_token, _spender, _amount);
    }

    function approve(address _token, address _spender, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).approve(_token, _spender, _amount);
    }

    function signalWithdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).signalWithdrawToken(_target, _token, _receiver, _amount);
    }

    function withdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).withdrawToken(_target, _token, _receiver, _amount);
    }

    function signalMint(address _token, address _receiver, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).signalMint(_token, _receiver, _amount);
    }

    function processMint(address _token, address _receiver, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).processMint(_token, _receiver, _amount);
    }

    function signalSetGov(address _target, address _gov) external onlyAdmin {
        ITimelock(timelockContract).signalSetGov(_target, _gov);
    }

    function setGov(address _target, address _gov) external onlyAdmin {
        ITimelock(timelockContract).setGov(_target, _gov);
    }

    function signalSetHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        ITimelock(timelockContract).signalSetHandler(_target, _handler, _isActive);
    }

    function setHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        ITimelock(timelockContract).setHandler(_target, _handler, _isActive);
    }

    function signalSetPriceFeed(address _vault, address _priceFeed) external onlyAdmin {
        ITimelock(timelockContract).signalSetPriceFeed(_vault, _priceFeed);
    }

    function setPriceFeed(address _vault, address _priceFeed) external onlyAdmin {
        ITimelock(timelockContract).setPriceFeed(_vault, _priceFeed);
    }

    function signalRedeemUsdb(address _vault, address _token, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).signalRedeemUsdb(_vault, _token, _amount);
    }

    function redeemUsdb(address _vault, address _token, uint256 _amount) external onlyAdmin {
        ITimelock(timelockContract).redeemUsdb(_vault, _token, _amount);
    }

    function signalVaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdbAmount,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        ITimelock(timelockContract).signalVaultSetTokenConfig(_vault, _token, _tokenDecimals, _tokenWeight, _minProfitBps, _maxUsdbAmount, _isStable, _isShortable);
    }

    function vaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdbAmount,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        ITimelock(timelockContract).vaultSetTokenConfig(_vault, _token, _tokenDecimals, _tokenWeight, _minProfitBps, _maxUsdbAmount, _isStable, _isShortable);
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        ITimelock(timelockContract).cancelAction(_action);
    }

    /* NEW */
    function setTimelockHandlerAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setTimelockHandlerTokenManager(address _tokenManager) external onlyAdmin {
        tokenManager = _tokenManager;
    }

    function setTimelockHandlerKeeper(address _keeper, bool _status) external onlyAdmin {
        isKeeper[_keeper] = _status;
    }

    function setTimelockHandlerHandler(address _handler, bool _status) external onlyAdmin {
        isKeeper[_handler] = _status;
    }

    function setTimelockHandlerFeesConfig(uint256 _ratioFeesCollectedPrimary, address _feesCollector1, address _feesCollector2) external onlyAdmin {
        ratioFeesCollectedPrimary = _ratioFeesCollectedPrimary;
        feesCollector1 = _feesCollector1;
        feesCollector2 = _feesCollector2;
    }

    function setTimelockHandlerVaultAndTokens(address _vault, address[] memory _tokens) external onlyAdmin {
        vault = _vault;
        tokens = _tokens;
    }

    function claimFees() external {        
        ITimelock(timelockContract).batchWithdrawFees(vault, tokens);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = IERC20(tokens[i]).balanceOf(address(this));
            uint256 TKNamount = amount.mul(ratioFeesCollectedPrimary).div(1000);
            uint256 TKN2amount = amount.sub(TKNamount);
            
            safeTKNTransfer(tokens[i], feesCollector1, TKNamount);
            safeTKNTransfer(tokens[i], feesCollector2, TKN2amount);
        }
    }

    function safeTKNTransfer(address _token, address _to, uint256 _amount) internal {
        uint256 TKNBal = IERC20(_token).balanceOf(address(this));
        if (_amount > TKNBal) {
            IERC20(_token).transfer(_to, TKNBal);
        } else {
            IERC20(_token).transfer(_to, _amount);
        }
    }
}

