// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {tuPHRS, MERC20} from "src/tokens/tuPHRS.sol";
import {WtuPHRS, ERC20} from "src/staking/wtuPHRS.sol";
import {NativeMinterRedeem, ERC20MinterRedeem} from "src/minters/tuPHRSMinter.sol";

contract TokenTest is Test {
    address owner = address(0x01);
    address user1 = address(0x02);
    address user2 = address(0x03);
    uint256 start = 1721475062;

    tuPHRS tuPHRS;
    WtuPHRS wtuPHRS;

    NativeMinterRedeem nativeMinter;
    ERC20MinterRedeem eRC20Minter;
    MERC20 erc20;

    function setUp() public {
        vm.startPrank(owner);

        vm.warp(10000000);
        tuPHRS = new tuPHRS("tuPHRS", "tuPHRS", 18);
        wtuPHRS = new WtuPHRS(ERC20(address(tuPHRS)), 1);
        tuPHRS.mint(user1, 10 ether);
        tuPHRS.mint(user2, 10 ether);
        tuPHRS.mint(address(this), 100 ether);

        nativeMinter = new NativeMinterRedeem(address(tuPHRS));
        erc20 = new MERC20("Mock", "Mock", 18);
        erc20.mint(address(owner), 1000 * 10 ** 18);
        eRC20Minter = new ERC20MinterRedeem(address(erc20), address(tuPHRS));
        tuPHRS.transferOwnership(address(eRC20Minter));
        vm.stopPrank();
    }

    function test_minter_deposit() public {
        vm.startPrank(owner);
        erc20.approve(address(eRC20Minter), type(uint).max);
        eRC20Minter.deposit(1 ether, owner);
    }

    function test_restake() public {
        tuPHRS.transfer(address(wtuPHRS), 1);

        vm.startPrank(user1);
        tuPHRS.approve(address(wtuPHRS), 4 ether);
        wtuPHRS.deposit(4 ether, user1);
        vm.stopPrank();

        vm.startPrank(user2);
        tuPHRS.approve(address(wtuPHRS), 4 ether);
        wtuPHRS.deposit(2 ether, user2);
        vm.stopPrank();
        console.log(
            "\n before rewards release: ================================== user token balance \n"
        );

        console.log("user1 tuPHRS balance: ", tuPHRS.balanceOf(user1));
        console.log("user1 wtuPHRS balance: ", wtuPHRS.balanceOf(user1));
        console.log("user2 tuPHRS balance: ", tuPHRS.balanceOf(user2));
        console.log("user2 wtuPHRS balance: ", wtuPHRS.balanceOf(user2));

        tuPHRS.transfer(address(wtuPHRS), 12 ether);
        vm.warp(start + 1);
        wtuPHRS.syncRewards();
        tuPHRS.transfer(address(wtuPHRS), 12);
        vm.warp(start + 2);
        wtuPHRS.syncRewards();

        console.log(
            "\n after rewards released: ================================== user token balance \n"
        );

        vm.startPrank(user1);
        wtuPHRS.redeem(wtuPHRS.balanceOf(user1), user1, user1);
        console.log("user1 tuPHRS balance: ", tuPHRS.balanceOf(user1));
        console.log("user1 wtuPHRS balance: ", wtuPHRS.balanceOf(user1));
        vm.stopPrank();

        vm.startPrank(user2);
        wtuPHRS.redeem(wtuPHRS.balanceOf(user2), user2, user2);
        console.log("user2 tuPHRS balance: ", tuPHRS.balanceOf(user2));
        console.log("user2 wtuPHRS balance: ", wtuPHRS.balanceOf(user2));
        vm.stopPrank();
    }
}
