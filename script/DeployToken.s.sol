// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TuPHRS, MERC20} from "src/tokens/tuPHRS.sol";
import {WtuPHRS} from "src/staking/wtuPHRS.sol";
import {ERC20} from "src/ERC20.sol";
import {NativeMinterRedeem, ERC20MinterRedeem, ERC20MinterWithdrawal, NativeMinterWithdrawal} from "src/minters/tuPHRSMinter.sol";

contract DeployScript is Script {
    tuPHRS tuPHRS;
    WtuPHRS wtuPHRS;
    // NativeMinterRedeem nativeMinter;
    // ERC20MinterRedeem eRC20Minter;
    ERC20MinterWithdrawal erc20Withdraw;
    NativeMinterWithdrawal nativeWithdraw;

    function setUp() public {}

    function run() public {
        deploy_tuPHRS();
    }

    function deploy_tuPHRS() public {
        uint8 decimals = 18;
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        uint32 rewardsCycleLength = 1; // 6s in seconds
        vm.startBroadcast(privateKey);
        tuPHRS = new tuPHRS("tuPHRS", "tuPHRS", decimals);
        wtuPHRS = new WtuPHRS(ERC20(address(tuPHRS)), rewardsCycleLength);
        tuPHRS.mint(address(wtuPHRS), 1);
        // nativeMinter = new NativeMinterRedeem(address(tuPHRS));
        MERC20 erc20 = new MERC20("Mock", "Mock", decimals);
        erc20.mint(address(deployer), 1000 * 10 ** 18);
        eRC20Minter = new ERC20MinterRedeem(address(erc20), address(tuPHRS));
        erc20Withdraw = new ERC20MinterWithdrawal(
            address(erc20),
            address(tuPHRS),
            "wd",
            "wd"
        );
        nativeWithdraw = new NativeMinterWithdrawal(
            address(tuPHRS),
            "wd",
            "wd"
        );
        tuPHRS.transferOwnership(address(erc20Withdraw));
        vm.stopBroadcast();
    }
}
