// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Dao} from "./Governor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract GovernorFactory {
    function createDao(
        string memory daoName,
        address voteToken,
        address timelockAddress
    ) public returns (address daoAddress) {
        TimelockController timelock = TimelockController(
            payable(timelockAddress)
        );
        // Create a new DAO contract
        bytes32 salt = keccak256(abi.encodePacked(timelockAddress, voteToken));
        Dao governor = new Dao{salt: salt}(
            IVotes(voteToken),
            timelock,
            daoName
        );
        daoAddress = address(governor);
        // Grant roles to governor
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governor));
    }

    function calculateDaoAddr(
        address timelock,
        address voteToken,
        string memory daoName
    ) public view returns (address predictedAddress) {
        bytes32 salt = keccak256(abi.encodePacked(timelock, voteToken));
        bytes memory constructorArgs = abi.encode(voteToken, timelock, daoName);
        bytes memory bytecode = abi.encodePacked(
            type(Dao).creationCode,
            constructorArgs
        );
        predictedAddress = Create2.computeAddress(salt, keccak256(bytecode));
    }
}
