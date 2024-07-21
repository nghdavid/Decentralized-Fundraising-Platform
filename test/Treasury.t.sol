// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Treasury} from "../src/Treasury.sol";
import {FundToken} from "../src/FundToken.sol";
import {VoteToken} from "../src/VoteToken.sol";
import {MyGovernor} from "../src/Governor.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract TreasuryTest is Test {
    Treasury treasury;
    FundToken fundToken;
    VoteToken voteToken;
    MyGovernor public governor;
    TimeLock public timelock;
    uint32 fundraiseTime = 1000; // fundraising duration
    uint32 duration = 100; // vesting duration of the vesting wallet

    address public constant company = address(0x6);
    address public constant investor1 = address(0x1);
    address public constant investor2 = address(0x2);

    function setUp() public {
        // Create a fund token and mint some tokens to investors
        fundToken = new FundToken(address(this));
        fundToken.mint(investor1, 1000e18);
        fundToken.mint(investor2, 1000e18);
        
        // Create a timelock and dao contract
        uint256 timelockDelay = 1;
        timelock = new TimeLock(timelockDelay, new address[](0), new address[](0), address(this));
        voteToken = new VoteToken(address(this));
        governor = new MyGovernor(voteToken, timelock, "MyDAO");
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.EXECUTOR_ROLE(), address(governor));

        // Create a investment treasury
        treasury = new Treasury(
            company,
            address(timelock),
            uint64(block.timestamp + fundraiseTime),
            duration,
            address(fundToken),
            address(voteToken)
        );
        voteToken.transferOwnership(address(treasury));

        // Investors approve the treasury to spend their funds
        vm.prank(investor1);
        fundToken.approve(address(treasury), 1000e18);
        vm.prank(investor2);
        fundToken.approve(address(treasury), 1000e18);
    }

    function testWithdraw() public {
        // Investors invest in the treasury
        uint256 investment = 1000e18;
        console.log("Investment is", investment*2);
        vm.prank(investor1);
        treasury.receiveFromInvestor(investment);
        vm.prank(investor1);
        voteToken.delegate(investor1);
        vm.prank(investor2);
        treasury.receiveFromInvestor(investment);
        vm.prank(investor2);
        voteToken.delegate(investor2);
        
        console.log("Before release, treasury has", fundToken.balanceOf(address(treasury)));
        // Move time to middle of vesting period
        vm.warp(block.timestamp + block.timestamp + fundraiseTime + duration / 2);
        vm.prank(company);
        // Treasury releases funds to company
        treasury.release(address(fundToken));
        console.log("Company gets", fundToken.balanceOf(company));
        console.log(
            "After release, treasury has",
            fundToken.balanceOf(address(treasury))
        );

        address[] memory targets = new address[](1); // Contract thats going to be called
        uint256[] memory values = new uint256[](1); // Ether to be sent
        bytes[] memory calldatas = new bytes[](1); // Function signature and parameters
        targets[0] = address(treasury);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(
            treasury.withdrawToInvestor.selector
        );

        string memory PROPOSAL_DESCRIPTION = "withdrawToInvestor";
        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            PROPOSAL_DESCRIPTION
        );

        // Voting starts
        vm.roll(block.number + governor.votingDelay() + 1);

        vm.prank(investor1);
        governor.castVote(proposalId, 1);
        vm.prank(investor2);
        governor.castVote(proposalId, 1);

        // Voting ends
        vm.roll(block.number + governor.votingPeriod());

        // Queue execution into timelock contract
        governor.queue(
            targets,
            values,
            calldatas,
            keccak256(abi.encodePacked(PROPOSAL_DESCRIPTION))
        );

        // After timelock delay, execute proposal
        vm.warp(block.timestamp + timelock.getMinDelay());
        governor.execute(
            targets,
            values,
            calldatas,
            keccak256(abi.encodePacked(PROPOSAL_DESCRIPTION))
        );

        console.log("Investor wallet1", fundToken.balanceOf(investor1));
        console.log("Investor wallet2", fundToken.balanceOf(investor2));
    }
}
