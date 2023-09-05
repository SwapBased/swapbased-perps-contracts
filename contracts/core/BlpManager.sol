// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IBlpManager.sol";
import "../tokens/interfaces/IUSDB.sol";
import "../tokens/interfaces/IMintable.sol";
import "../access/Governable.sol";

contract BlpManager is ReentrancyGuard, Governable, IBlpManager {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant PRICE_PRECISION = 10**30;
    uint256 public constant USDB_DECIMALS = 18;
    uint256 public constant MAX_COOLDOWN_DURATION = 48 hours;

    IVault public vault;
    address public override usdb;
    address public blp;

    uint256 public override cooldownDuration;
    mapping(address => uint256) public override lastAddedAt;

    uint256 public aumAddition;
    uint256 public aumDeduction;

    bool public inPrivateMode;
    mapping(address => bool) public isHandler;

    event AddLiquidity(address account, address token, uint256 amount, uint256 aumInUsdb, uint256 blpSupply, uint256 usdbAmount, uint256 mintAmount);

    event RemoveLiquidity(address account, address token, uint256 blpAmount, uint256 aumInUsdb, uint256 blpSupply, uint256 usdbAmount, uint256 amountOut);

    constructor(
        address _vault,
        address _usdb,
        address _blp,
        uint256 _cooldownDuration
    ) public {
        gov = msg.sender;
        vault = IVault(_vault);
        usdb = _usdb;
        blp = _blp;
        cooldownDuration = _cooldownDuration;
    }

    function setInPrivateMode(bool _inPrivateMode) external onlyGov {
        inPrivateMode = _inPrivateMode;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    function setCooldownDuration(uint256 _cooldownDuration) external override onlyGov {
        require(_cooldownDuration <= MAX_COOLDOWN_DURATION, "BlpManager: invalid _cooldownDuration");
        cooldownDuration = _cooldownDuration;
    }

    function setAumAdjustment(uint256 _aumAddition, uint256 _aumDeduction) external onlyGov {
        aumAddition = _aumAddition;
        aumDeduction = _aumDeduction;
    }

    function addLiquidity(
        address _token,
        uint256 _amount,
        uint256 _minUsdb,
        uint256 _minBlp
    ) external override nonReentrant returns (uint256) {
        if (inPrivateMode) {
            revert("BlpManager: action not enabled");
        }
        return _addLiquidity(msg.sender, msg.sender, _token, _amount, _minUsdb, _minBlp);
    }

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdb,
        uint256 _minBlp
    ) external override nonReentrant returns (uint256) {
        _validateHandler();
        return _addLiquidity(_fundingAccount, _account, _token, _amount, _minUsdb, _minBlp);
    }

    function removeLiquidity(
        address _tokenOut,
        uint256 _blpAmount,
        uint256 _minOut,
        address _receiver
    ) external override nonReentrant returns (uint256) {
        if (inPrivateMode) {
            revert("BlpManager: action not enabled");
        }
        return _removeLiquidity(msg.sender, _tokenOut, _blpAmount, _minOut, _receiver);
    }

    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _blpAmount,
        uint256 _minOut,
        address _receiver
    ) external override nonReentrant returns (uint256) {
        _validateHandler();
        return _removeLiquidity(_account, _tokenOut, _blpAmount, _minOut, _receiver);
    }

    function getAums() public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = getAum(true);
        amounts[1] = getAum(false);
        return amounts;
    }

    function getAumInUsdb(bool maximise) public view returns (uint256) {
        uint256 aum = getAum(maximise);
        return aum.mul(10**USDB_DECIMALS).div(PRICE_PRECISION);
    }

    function getAum(bool maximise) public view returns (uint256) {
        uint256 length = vault.allWhitelistedTokensLength();
        uint256 aum = aumAddition;
        uint256 shortProfits = 0;

        for (uint256 i = 0; i < length; i++) {
            address token = vault.allWhitelistedTokens(i);
            bool isWhitelisted = vault.whitelistedTokens(token);

            if (!isWhitelisted) {
                continue;
            }

            uint256 price = maximise ? vault.getMaxPrice(token) : vault.getMinPrice(token);
            uint256 poolAmount = vault.poolAmounts(token);
            uint256 decimals = vault.tokenDecimals(token);

            if (vault.stableTokens(token)) {
                aum = aum.add(poolAmount.mul(price).div(10**decimals));
            } else {
                // add global short profit / loss
                uint256 size = vault.globalShortSizes(token);
                if (size > 0) {
                    uint256 averagePrice = vault.globalShortAveragePrices(token);
                    uint256 priceDelta = averagePrice > price ? averagePrice.sub(price) : price.sub(averagePrice);
                    uint256 delta = size.mul(priceDelta).div(averagePrice);
                    if (price > averagePrice) {
                        // add losses from shorts
                        aum = aum.add(delta);
                    } else {
                        shortProfits = shortProfits.add(delta);
                    }
                }

                aum = aum.add(vault.guaranteedUsd(token));

                uint256 reservedAmount = vault.reservedAmounts(token);
                aum = aum.add(poolAmount.sub(reservedAmount).mul(price).div(10**decimals));
            }
        }

        aum = shortProfits > aum ? 0 : aum.sub(shortProfits);
        return aumDeduction > aum ? 0 : aum.sub(aumDeduction);
    }

    function _addLiquidity(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdb,
        uint256 _minBlp
    ) private returns (uint256) {
        require(_amount > 0, "BlpManager: invalid _amount");

        // calculate aum before buyUSDB
        uint256 aumInUsdb = getAumInUsdb(true);
        uint256 blpSupply = IERC20(blp).totalSupply();

        IERC20(_token).safeTransferFrom(_fundingAccount, address(vault), _amount);
        uint256 usdbAmount = vault.buyUSDB(_token, address(this));
        require(usdbAmount >= _minUsdb, "BlpManager: insufficient USDB output");

        uint256 mintAmount = aumInUsdb == 0 ? usdbAmount : usdbAmount.mul(blpSupply).div(aumInUsdb);
        require(mintAmount >= _minBlp, "BlpManager: insufficient BLP output");

        IMintable(blp).mint(_account, mintAmount);

        lastAddedAt[_account] = block.timestamp;

        emit AddLiquidity(_account, _token, _amount, aumInUsdb, blpSupply, usdbAmount, mintAmount);

        return mintAmount;
    }

    function _removeLiquidity(
        address _account,
        address _tokenOut,
        uint256 _blpAmount,
        uint256 _minOut,
        address _receiver
    ) private returns (uint256) {
        require(_blpAmount > 0, "BlpManager: invalid _blpAmount");
        require(lastAddedAt[_account].add(cooldownDuration) <= block.timestamp, "BlpManager: cooldown duration not yet passed");

        // calculate aum before sellUSDB
        uint256 aumInUsdb = getAumInUsdb(false);
        uint256 blpSupply = IERC20(blp).totalSupply();

        uint256 usdbAmount = _blpAmount.mul(aumInUsdb).div(blpSupply);
        uint256 usdbBalance = IERC20(usdb).balanceOf(address(this));
        if (usdbAmount > usdbBalance) {
            IUSDB(usdb).mint(address(this), usdbAmount.sub(usdbBalance));
        }

        IMintable(blp).burn(_account, _blpAmount);

        IERC20(usdb).transfer(address(vault), usdbAmount);
        uint256 amountOut = vault.sellUSDB(_tokenOut, _receiver);
        require(amountOut >= _minOut, "BlpManager: insufficient output");

        emit RemoveLiquidity(_account, _tokenOut, _blpAmount, aumInUsdb, blpSupply, usdbAmount, amountOut);

        return amountOut;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "BlpManager: forbidden");
    }
}
