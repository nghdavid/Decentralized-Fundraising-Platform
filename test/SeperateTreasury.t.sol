// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TreasuryFactory} from "../src/NewTreasuryFactory.sol";
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
        
        uint256 timelockDelay = 1;
        timelock = new TimeLock(timelockDelay, new address[](0), new address[](0), address(governorFactory));
        voteToken = new VoteToken(address(treasuryFactory));
        address daoAddress = governorFactory.createDao(daoName, address(voteToken), address(timelock));
        
        treasuryFactory.createTreasury(
            daoName,
            address(fundToken),
            address(voteToken),
            address(timelock),
            company,
            timelockDelay,
            fundraiseTime,
            duration
        );

        DAOInfo memory daoinfo = treasuryFactory.getDAOInfo(address(this), company)[0];
        address dao = governorFactory.calculateDaoAddr(daoinfo.timelock, daoinfo.voteToken, daoinfo.daoName);
        console.log("Timelock", daoinfo.timelock);
        console.log("VoteToken", daoinfo.voteToken);
        console.log("Treasury", daoinfo.treasury);
        console.log("DAO address", dao);  
    }

    function testWithdraw() public {
    }
}
