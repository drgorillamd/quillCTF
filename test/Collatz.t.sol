// SPDX-License-Identifier: None
pragma solidity 0.8.7;

import { Test } from "forge-std/Test.sol";
import { ICollatz, CollatzPuzzle } from "../src/CollatzPuzzle.sol";

/**
 * @title   Answer to the Collatz Puzzle Challenge
 * @notice  Produce a contract which return a collatz iteration, for a given input,
 *          in less than 32 bytes.
 *          To do so, use of assembly, in order to easily include it in this test
 *          alternative being yul or huff but:
 *              1) it would have needed a second file
 *              for the source code and proper system setup for the reader
 *              2) real assembly is funnier
 *          This could have been optimized further (ie less than the current 29 bytes) but
 *          it's working like this, so...   
 * @author  DrGorilla.eth
 */
contract CollatzPuzzleTest is Test {
    CollatzPuzzle _contract;

    function setUp() public {
        _contract = new CollatzPuzzle();
    }

    function testPuzzle() public {
        address _solution = deployCollatz();
        assertTrue(_contract.callMe(address(_solution)));
    }

    function deployCollatz() internal returns(address _deployment) {
        // For the correspoding assembly, see below - first hex string is the constructor, second the runtime code
        bytes memory bytecode = hex"601f600c600039601f6000f3" hex"60043560028106601157600290046018565b6003026001015b3452602034f3";

        assembly {
            _deployment := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(
            _deployment != address(0),
            "Life sucks"
        );
    }
}


/**

Constructor (home-made even tho size optim not needed as not part of runtime bytecode)

// codecopy(at offset 0, from 13 (constructor size) to 1f (whole code size))
push1 0x1d
push1 0x0c
push1 0x00
codecopy
// return (at offset 0, size 31)
push1 0x1d
push1 0x00
return

Runtime code, with stack (top on the left)
push1 0x04         // [0x04]
calldataload       // [q]
dup1               // [q; q]
push1 0x02         // [0x02; q; q] - 2 for the modulo
mod                // [module; q]
push1 0x0a         // [0x0a; module; q] - 0x0a is the jumpdest if module is 0
jumpi              // [q]

// no jump if modulo was not 0
push1 0x03         // [0x03; q]
mul                // [3*q]
push1 0x01         // [0x01; 3*q]
add                // [3*q + 1]
push1 0x06         // [0x06; 3*q + 1] - 0x06 is the jumpdest for the end of the function
jump               // [3q+1]

// dest if the modulo was 0
jumpdest            // [q]
push1 0x02          // [0x02; q] - 2 for the division
swap1               // [q; 0x02]
div                 // [q/2]

// End of execution -> copying in memory, offset 0 (no mem management needed, end of context) and return 32bytes
jumpdest
push1 0x20
calldatavalue
return
*/