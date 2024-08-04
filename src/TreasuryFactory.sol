// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Treasury} from "./Treasury.sol";
import {DAOInfo} from "./utils/DaoStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TreasuryFactory {
    mapping(address => mapping(address => DAOInfo[])) public DAOInfos;

    function createTreasury(
        string memory fundraiseName,
        address fundToken,
        address voteToken,
        address timelock,
        address company,
        uint32 fundraiseTime,
        uint32 duration
    ) public returns (address treasuryAddress) {
        // Create a treasury contract
        bytes32 salt = keccak256(abi.encodePacked(timelock, voteToken));
        Treasury treasury = new Treasury{salt: salt}(company);
        treasury.initialize(
            timelock,
            fundToken,
            voteToken,
            uint64(block.timestamp + fundraiseTime),
            duration
        );
        treasuryAddress = address(treasury);

        // Store fundraise information
        DAOInfos[msg.sender][company].push(
            DAOInfo(timelock, voteToken, fundraiseName)
        );
        // Vote token shouldn't be minted before
        require(
            IERC20(voteToken).totalSupply() == 0,
            "Vote token already minted"
        );
        // Transfer ownership of vote token to treasury
        Ownable voteTokenOwnable = Ownable(voteToken);
        voteTokenOwnable.transferOwnership(address(treasury));
    }

    function getDAOInfo(
        address crowdfundingInitiator,
        address company
    ) public view returns (DAOInfo[] memory) {
        return DAOInfos[crowdfundingInitiator][company];
    }

    function calculateTreasuryAddr(
        address timelock,
        address voteToken,
        address company
    ) public view returns (address predictedAddress) {
        bytes32 salt = keccak256(abi.encodePacked(timelock, voteToken));
        bytes memory constructorArgs = abi.encode(company);
        bytes memory bytecode = abi.encodePacked(
            type(Treasury).creationCode,
            constructorArgs
        );
        predictedAddress = Create2.computeAddress(salt, keccak256(bytecode));
    }
}
