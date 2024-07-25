// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TimeLock.sol";
import "./Governor.sol";
import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract GovernorFactory {
    function createDao(
        string memory _daoName,
        address voteToken,
        address timelock
    ) public returns (address daoAddress) {
        bytes32 salt = keccak256(
            abi.encodePacked(timelock, voteToken)
        );
        TimelockController timelock = TimelockController(payable(timelock));
        MyGovernor governor = new MyGovernor{salt: salt}(IVotes(voteToken), timelock, _daoName);
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governor));
        daoAddress = address(governor);
    }

    function calculateDaoAddr(
        address timelock,
        address voteToken,
        string memory daoName
    ) public view returns (address predictedAddress) {
        bytes32 salt = keccak256(abi.encodePacked(timelock, voteToken));
        bytes memory constructorArgs = abi.encode(voteToken, timelock, daoName);
        bytes memory bytecode = abi.encodePacked(type(MyGovernor).creationCode, constructorArgs);
        predictedAddress = Create2.computeAddress(salt, keccak256(bytecode));
    }
}
