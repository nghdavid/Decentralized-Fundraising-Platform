// SPDX-License-Identifier: MIT
// Modified OpenZeppelin Contracts (last updated v5.0.0) (finance/VestingWallet.sol)
pragma solidity ^0.8.20;
import {VestingWallet} from "./VestingWallet.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20Mint} from "./interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract Treasury is VestingWallet, AccessControl {
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    address public fundToken;
    address public daoToken; // Vote token
    uint256 private _totalShares; // Total shares of the investors
    mapping(address => uint256) private _shares; // Shares of the investors
    address[] private _payees; // Investors list
    bool private _initialized;

    event PayeeAdded(address account, uint256 shares);

    modifier initializer() {
        require(
            !_initialized,
            "Contract instance has already been initialized"
        );
        _initialized = true;
        _;
    }

    constructor(address beneficiary) VestingWallet(beneficiary) {}

    function initialize(
        address timelock,
        address _token,
        address _daoToken,
        uint64 _startTimestamp,
        uint64 _durationSeconds
    ) public initializer {
        VestingWallet.initialize(_startTimestamp, _durationSeconds);
        _grantRole(DAO_ROLE, timelock);
        fundToken = _token;
        daoToken = _daoToken;
    }

    // Return fund to investors (Can only be called by DAO)
    function withdrawToInvestor() public onlyRole(DAO_ROLE) {
        // Can retrieve investment only after the fundraising period
        require(
            block.timestamp > VestingWallet.start(),
            "Funding has not ended"
        );
        IERC20Mint fundedToken = IERC20Mint(fundToken);
        uint256 total_amount = fundedToken.balanceOf(address(this));
        require(total_amount > 0, "No funds to withdraw");
        for (uint i = 0; i < _payees.length; i++) {
            fundedToken.transfer(
                _payees[i],
                (total_amount * _shares[_payees[i]]) / _totalShares
            );
        }
    }

    // Investors send funds to the treasury
    function receiveFromInvestor(uint256 amount) public {
        // Cannot invest after the fundraising period
        require(block.timestamp < VestingWallet.start(), "Funding has ended");
        // Transfer the fund token from the investor to the treasury
        IERC20Mint fundedToken = IERC20Mint(fundToken);
        require(
            fundedToken.allowance(msg.sender, address(this)) >= amount,
            "Insufficient allowance"
        );
        fundedToken.transferFrom(msg.sender, address(this), amount);
        // Record the investor's shares
        _addPayee(msg.sender, amount);
        // Mint voteToken to the investor
        IERC20Mint voteToken = IERC20Mint(daoToken);
        voteToken.mint(msg.sender, amount);
    }

    // Record the investor's shares
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
