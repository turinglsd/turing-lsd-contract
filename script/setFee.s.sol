// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {tuPHRS, MERC20} from "src/tokens/tuPHRS.sol";
import {WtuPHRS, ERC20} from "src/staking/wtuPHRS.sol";
import {NativeMinterWithdrawal, ERC20MinterWithdrawal} from "src/minters/tuPHRSMinter.sol";

contract SetFeeScript is Script {
    NativeMinterWithdrawal withdrawMinter;

    function setUp() public {}

    function run() public {
        set_ownership();
    }

    function set_ownership() public {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        // set ownership
        address withdrawMinterAddr = 0xf9C1aa3d3d2200EA2C2eEea99ed77173bF2164e1;
        tuPHRS tuPHRS = tuPHRS(0xE2E9fB0f2A42ceECa5d3c6C798dd115B616a9581);
        tuPHRS.transferOwnership(withdrawMinterAddr);
        vm.stopBroadcast();
    }
}
