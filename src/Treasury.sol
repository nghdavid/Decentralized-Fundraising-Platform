// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (finance/VestingWallet.sol)
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/finance/VestingWallet.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20Mint} from "./interfaces/IERC20.sol";
contract Treasury is VestingWallet, AccessControl {
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    address public token;
    address public daoToken;
    uint64 public startTimestamp;
    uint256 private _totalShares;
    mapping(address => uint256) private _shares;
    address[] private _payees;

    event PayeeAdded(address account, uint256 shares);

    constructor(
        address beneficiary,
        address dao,
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        address _token,
        address _daoToken
    ) VestingWallet(beneficiary, _startTimestamp, _durationSeconds) {
        _grantRole(DAO_ROLE, dao);
        token = _token;
        daoToken = _daoToken;
        startTimestamp = _startTimestamp;
    }

    function withdrawToInvestor() public onlyRole(DAO_ROLE) {
        IERC20Mint fundedToken = IERC20Mint(token);
        uint256 total_amount = fundedToken.balanceOf(address(this));
        require(total_amount > 0, "No funds to withdraw");
        for (uint i = 0; i < _payees.length; i++) {
            fundedToken.transfer(_payees[i], total_amount * _shares[_payees[i]] / _totalShares);
        }
    }

    function receiveFromInvestor(uint256 amount) public {
        require(block.timestamp < startTimestamp, "Funding has ended");
        IERC20Mint fundedToken = IERC20Mint(token);
        require(
            fundedToken.allowance(msg.sender, address(this)) >= amount,
            "Insufficient allowance"
        );
        fundedToken.transferFrom(msg.sender, address(this), amount);
        _addPayee(msg.sender, amount);
        IERC20Mint voteToken = IERC20Mint(daoToken);
        voteToken.mint(msg.sender, amount);
    }

    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0));
        if (_shares[account] == 0) {
            _payees.push(account);
            _shares[account] = shares_;
        } else {
            _shares[account] += shares_;
        }
        _totalShares += shares_;
        emit PayeeAdded(account, shares_);
    }
}
