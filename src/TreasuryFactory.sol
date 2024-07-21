// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Treasury.sol";
import "./VoteToken.sol";
import "./TimeLock.sol";
import "./Governor.sol";
import {DAOInfo} from "./utils/DaoStorage.sol";
import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract TreasuryFactory {
    DAOInfo[] public DAOs;
    mapping(address => mapping(address => DAOInfo[])) public DAOInfos;

    function createTreasury(
        string memory _daoName,
        address fundToken,
        address company,
        uint256 timelockDelay,
        uint32 fundraiseTime,
        uint32 duration
    ) public {
        TimeLock timelock = new TimeLock(
            timelockDelay,
            new address[](0),
            new address[](0),
            address(this)
        );
        VoteToken voteToken = new VoteToken(address(this));
        
        bytes32 salt = keccak256(
            abi.encodePacked(address(timelock), address(voteToken))
        );
        MyGovernor governor = new MyGovernor{salt: salt}(voteToken, timelock, _daoName);
        
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governor));

        Treasury treasury = new Treasury{salt: salt}(
            company,
            address(timelock),
            uint64(block.timestamp + fundraiseTime),
            duration,
            fundToken,
            address(voteToken)
        );

        DAOInfos[msg.sender][company].push(
            DAOInfo(address(timelock), address(voteToken), address(treasury), _daoName)
        );

        voteToken.transferOwnership(address(treasury));
    }

    function getDAOInfo(
        address crowdfundingInitiator,
        address company
    ) public view returns (DAOInfo[] memory) {
        return DAOInfos[crowdfundingInitiator][company];
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
