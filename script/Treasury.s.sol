// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {TreasuryFactory} from "../src/TreasuryFactory.sol";
import {FundToken} from "../src/FundToken.sol";
import {DAOInfo} from "../src/utils/DaoStorage.sol";


contract TreasuryScript is Script {
    string daoName = "MyDAO";
    address public constant company = address(0x6);
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

        TreasuryFactory treasuryFactory = new TreasuryFactory();
        // treasuryFactory.createTreasury(
        //     daoName,
        //     0x022A71b546560C2b28732333Bcd434e555426ECF,
        //     company,
        //     timelockDelay,
        //     fundraiseTime,
        //     duration
        // );

        // DAOInfo memory daoinfo = treasuryFactory.getDAOInfo(account, company)[
        //     0
        // ];
        // address dao = treasuryFactory.calculateDaoAddr(
        //     daoinfo.timelock,
        //     daoinfo.voteToken,
        //     daoinfo.daoName
        // );
        // console.log("Timelock", daoinfo.timelock);
        // console.log("VoteToken", daoinfo.voteToken);
        // console.log("Treasury", daoinfo.treasury);
        // console.log("DAO address", dao);

        vm.stopBroadcast();
    }
}
