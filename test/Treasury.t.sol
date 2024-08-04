// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TreasuryFactory} from "../src/TreasuryFactory.sol";
import {GovernorFactory} from "../src/GovernorFactory.sol";
import {Treasury} from "../src/Treasury.sol";
import {FundToken} from "../src/FundToken.sol";
import {VoteToken} from "../src/VoteToken.sol";
import {MyGovernor} from "../src/Governor.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {DAOInfo} from "../src/utils/DaoStorage.sol";

contract NewTreasuryTest is Test {
    Treasury treasury;
    TreasuryFactory treasuryFactory;
    GovernorFactory governorFactory;
    FundToken fundToken;
    VoteToken voteToken;
    MyGovernor public governor;
    TimeLock public timelock;
    uint32 fundraiseTime = 1000; // fundraising duration
    uint32 duration = 100; // vesting duration of the vesting wallet
    string daoName = "MyDAO";
    uint256 public constant timelockDelay = 1;
    address public constant company = address(0x6);
    address public constant investor1 = address(0x1);
    address public constant investor2 = address(0x2);

    function setUp() public {
        // Create a fund token and mint some tokens to investors
        fundToken = new FundToken(address(this));
        fundToken.mint(investor1, 1000e18);
        fundToken.mint(investor2, 1000e18);

        governorFactory = new GovernorFactory();
        treasuryFactory = new TreasuryFactory();

        timelock = new TimeLock(
            timelockDelay,
            new address[](0),
            new address[](0),
            address(governorFactory)
        );
        voteToken = new VoteToken(address(treasuryFactory));
        address daoAddress = governorFactory.createDao(
            daoName,
            address(voteToken),
            address(timelock)
        );

        address treasuryAddress = treasuryFactory.createTreasury(
            daoName,
            address(fundToken),
            address(voteToken),
            address(timelock),
            company,
            fundraiseTime,
            duration
        );
        
        DAOInfo memory daoinfo = treasuryFactory.getDAOInfo(
            address(this),
            company
        )[0];
        
        address treasuryAddr = treasuryFactory.calculateTreasuryAddr(
            address(timelock),
            address(voteToken),
            company
        );
        console.log("Treasury", treasuryAddr);

        // address dao = governorFactory.calculateDaoAddr(daoinfo.timelock, daoinfo.voteToken, daoinfo.daoName);
        // console.log("Timelock", daoinfo.timelock);
        // console.log("VoteToken", daoinfo.voteToken);
        // console.log("Treasury", daoinfo.treasury);
        // console.log("DAO address", dao);

        // Investors approve the treasury to spend their funds
        vm.prank(investor1);
        fundToken.approve(daoinfo.treasury, 1000e18);
        vm.prank(investor2);
        fundToken.approve(daoinfo.treasury, 1000e18);

        governor = MyGovernor(payable(daoAddress));
        treasury = Treasury(payable(daoinfo.treasury));
        timelock = TimeLock(payable(daoinfo.timelock));
        voteToken = VoteToken(daoinfo.voteToken);
    }

    function testWithdraw() public {
        // Investors invest in the treasury
        uint256 investment = 1000e18;
        console.log("Investment is", investment * 2);
        vm.prank(investor1);
        treasury.receiveFromInvestor(investment);
        vm.prank(investor1);
        voteToken.delegate(investor1);
        vm.prank(investor2);
        treasury.receiveFromInvestor(investment);
        vm.prank(investor2);
        voteToken.delegate(investor2);

        console.log(
            "Before release, treasury has",
            fundToken.balanceOf(address(treasury))
        );
        // Move time to middle of vesting period
        vm.warp(
            block.timestamp + block.timestamp + fundraiseTime + duration / 2
        );
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
