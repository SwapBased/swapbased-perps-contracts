// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../core/interfaces/IBlpManager.sol";

contract BlpBalance {
    using SafeMath for uint256;

    IBlpManager public blpManager;
    address public stakedBlpTracker;

    mapping(address => mapping(address => uint256)) public allowances;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(IBlpManager _blpManager, address _stakedBlpTracker) public {
        blpManager = _blpManager;
        stakedBlpTracker = _stakedBlpTracker;
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
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "BlpBalance: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "BlpBalance: approve from the zero address");
        require(_spender != address(0), "BlpBalance: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(_sender != address(0), "BlpBalance: transfer from the zero address");
        require(_recipient != address(0), "BlpBalance: transfer to the zero address");

        require(blpManager.lastAddedAt(_sender).add(blpManager.cooldownDuration()) <= block.timestamp, "BlpBalance: cooldown duration not yet passed");

        IERC20(stakedBlpTracker).transferFrom(_sender, _recipient, _amount);
    }
}
