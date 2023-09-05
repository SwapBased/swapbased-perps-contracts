// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

import "../core/interfaces/IBlpManager.sol";

import "./interfaces/IRewardTracker.sol";

contract StakedBlp {
    using SafeMath for uint256;

    string public constant name = "StakedBlp";
    string public constant symbol = "sBLP";
    uint8 public constant decimals = 18;

    address public blp;
    IBlpManager public blpManager;
    address public stakedBlpTracker;
    address public feeBlpTracker;

    mapping(address => mapping(address => uint256)) public allowances;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        address _blp,
        IBlpManager _blpManager,
        address _stakedBlpTracker,
        address _feeBlpTracker
    ) public {
        blp = _blp;
        blpManager = _blpManager;
        stakedBlpTracker = _stakedBlpTracker;
        feeBlpTracker = _feeBlpTracker;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) external returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "StakedBlp: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function balanceOf(address _account) external view returns (uint256) {
        IRewardTracker(stakedBlpTracker).depositBalances(_account, blp);
    }

    function totalSupply() external view returns (uint256) {
        IERC20(stakedBlpTracker).totalSupply();
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "StakedBlp: approve from the zero address");
        require(_spender != address(0), "StakedBlp: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(_sender != address(0), "StakedBlp: transfer from the zero address");
        require(_recipient != address(0), "StakedBlp: transfer to the zero address");

        require(blpManager.lastAddedAt(_sender).add(blpManager.cooldownDuration()) <= block.timestamp, "StakedBlp: cooldown duration not yet passed");

        IRewardTracker(stakedBlpTracker).unstakeForAccount(_sender, feeBlpTracker, _amount, _sender);
        IRewardTracker(feeBlpTracker).unstakeForAccount(_sender, blp, _amount, _sender);

        IRewardTracker(feeBlpTracker).stakeForAccount(_sender, _recipient, blp, _amount);
        IRewardTracker(stakedBlpTracker).stakeForAccount(_recipient, _recipient, feeBlpTracker, _amount);
    }
}
