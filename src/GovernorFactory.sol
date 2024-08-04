// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MyGovernor} from "./Governor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract GovernorFactory {
    function createDao(
        string memory _daoName,
        address voteToken,
        address timelockAddress
    ) public returns (address daoAddress) {
        bytes32 salt = keccak256(abi.encodePacked(timelockAddress, voteToken));
        TimelockController timelock = TimelockController(
            payable(timelockAddress)
        );
        MyGovernor governor = new MyGovernor{salt: salt}(
            IVotes(voteToken),
            timelock,
            _daoName
        );
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governor));
        daoAddress = address(governor);
    }
}
