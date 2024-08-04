// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {GovernorFactory} from "../src/GovernorFactory.sol";
import {TreasuryFactory} from "../src/TreasuryFactory.sol";
import {FundToken} from "../src/FundToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {VoteToken} from "../src/VoteToken.sol";
import {DAOInfo} from "../src/utils/DaoStorage.sol";

contract TreasuryScript is Script {
    string fundraiseName = "MyDAO";
    address public constant company = address(0x6);
    address public constant fundTokenAddr =
        0x022A71b546560C2b28732333Bcd434e555426ECF;
    uint256 public constant timelockDelay = 1;
    uint32 fundraiseTime = 1000; // fundraising duration
    uint32 duration = 100; // vesting duration of the vesting wallet
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("DEV_PRIVATE_KEY");
        address account = vm.addr(privateKey);
        console.log("Account", account);
        vm.startBroadcast(privateKey);

        // FundToken fundToken = new FundToken(account);
        // console.log("FundToken", address(fundToken));
        // fundToken.mint(account, 1000e18);

        GovernorFactory governorFactory = new GovernorFactory();
        TreasuryFactory treasuryFactory = new TreasuryFactory();

        TimeLock timelock = new TimeLock(
            timelockDelay,
            new address[](0),
            new address[](0),
            address(governorFactory)
        );

        VoteToken voteToken = new VoteToken(address(treasuryFactory));

        address daoAddress = governorFactory.createDao(
            fundraiseName,
            address(voteToken),
            address(timelock)
        );

        address treasuryAddress = treasuryFactory.createTreasury(
            fundraiseName,
            fundTokenAddr,
            address(voteToken),
            address(timelock),
            account,
            fundraiseTime,
            duration
        );

        DAOInfo[] memory daoinfos = treasuryFactory.getDAOInfo(
            account,
            account
        );
        DAOInfo memory daoinfo = daoinfos[daoinfos.length - 1];

        address calDaoAddress = governorFactory.calculateDaoAddr(
            daoinfo.timelock,
            daoinfo.voteToken,
            daoinfo.fundraiseName
        );

        address calTreasuryAddr = treasuryFactory.calculateTreasuryAddr(
            address(timelock),
            address(voteToken),
            account
        );

        console.log("GovernorFactory", address(governorFactory));
        console.log("TreasuryFactory", address(treasuryFactory));
        console.log("Timelock", address(timelock));
        console.log("VoteToken", address(voteToken));
        console.log("DAO", daoAddress);
        console.log("Calculated DAO", calDaoAddress);
        console.log("Treasury", treasuryAddress);
        console.log("Calculated Treasury", calTreasuryAddr);

        vm.stopBroadcast();
    }
}
