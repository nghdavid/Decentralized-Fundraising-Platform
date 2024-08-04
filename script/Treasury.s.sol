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

        // GovernorFactory governorFactory = new GovernorFactory();
        GovernorFactory governorFactory = GovernorFactory(
            0x5b9CcF2EcC30047A98D915fF52777dcAB07d7cAA
        );
        TreasuryFactory treasuryFactory = TreasuryFactory(
            0xec36dB616887ED68d6421F5004e8081c898675DC
        );
        // TimeLock timelock = new TimeLock(
        //     timelockDelay,
        //     new address[](0),
        //     new address[](0),
        //     address(governorFactory)
        // );
        
        TimeLock timelock = TimeLock(
            payable(0x516eE259CebB40E544d6D2b68d2b96C57DFD6C5f)
        );
        VoteToken voteToken = new VoteToken(address(treasuryFactory));
        
        // address daoAddress = governorFactory.createDao(
        //     daoName,
        //     address(voteToken),
        //     address(timelock)
        // );

        address treasuryAddress = treasuryFactory.createTreasury(
            daoName,
            0x022A71b546560C2b28732333Bcd434e555426ECF,
            address(voteToken),
            address(timelock),
            account,
            fundraiseTime,
            duration
        );

        DAOInfo[] memory daoinfos = treasuryFactory.getDAOInfo(account, account);
        DAOInfo memory daoinfo = daoinfos[daoinfos.length - 1];
        // address dao = governorFactory.calculateDaoAddr(
        //     daoinfo.timelock,
        //     daoinfo.voteToken,
        //     daoinfo.daoName
        // );
        address calTreasuryAddr = treasuryFactory.calculateTreasuryAddr(
            address(timelock),
            address(voteToken),
            account
        );
        console.log("Timelock", address(timelock));
        console.log("VoteToken", address(voteToken));
        console.log("DAO address", 0x015034bd9e594a29FE544bD9F3713241Ff396b14);
        console.log("Treasury", daoinfo.treasury);
        console.log("Treasury", treasuryAddress);
        console.log("Calculated Treasury", calTreasuryAddr);
        console.log("GovernorFactory", address(governorFactory));
        console.log("TreasuryFactory", address(treasuryFactory));

        vm.stopBroadcast();
    }
}
