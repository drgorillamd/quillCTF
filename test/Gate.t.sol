// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { Gate, IGuardian } from "../src/Gate.sol";

/**
 * @title   Answer to the Gate Challenge
 *
 * @notice  The logic summarized is, for every calls to guardian, the following
 *          should be returned, according to the function selector called:
 *              "f00000000_bvvvdlt" -> sig=0x000000000 -> return caller
 *              "f00000001_grffjzz" -> sig=0x000000001 -> return tx.origin
 *              "fail()" -> revert
 *
 * @dev     This solution uses a branchless approach: the function selector is
 *          shifted by 28 bytes to the right, and multiplied by the offset of the 
 *          corresponding function. If the selector is 0, the result is 0, and the
 *          jumpi instruction doesn't jump. If the selector is 1, the result is
 *          the offset of the corresponding function, and the jumpi instruction
 *          jumps to it. If the selector is anything else, the result is a random
 *          non jumpdest, and the jumpi instruction reverts.
 *          The rest of the code is just managing returned value.
 *          Current size is 29 bytes - can do better :/
 *      
 * @author  DrGorilla.eth
 */
contract GateTest is Test {
    Gate _contract;

    function setUp() public {
        _contract = new Gate();
    }

    function testGate() public {
        address _solution = deployGuardian();

        _contract.open(_solution);

        assertTrue(_contract.opened());
    }

    function deployGuardian() internal returns(address _deployment) {
        // For the corresponding assembly, see below
        bytes memory bytecode = hex"6018600c600039601d6000f3" hex"3d35600e8160e01c0257336010565b325b3d5260203df3";

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

// ---------------------------------------


// branchless:
// if calldata == 0 -> calldata * offset = 0 (but jumpi doesn't jump)
// if calldata == 1 ->  calldata * offset = offset
// else calldata * offset = a random non jumpdest (-> reverts)

returndatasize
calldataload      // [calldata]
push1 0x0e        // [offsetO, calldata]
dup2              // [calldata, offset0, calldata]

push1 224         // [224; calldata; offsetO, calldata] need to shift calldata by 28 bytes, as the fn selector is 4 bytes
shr               // [calldata >> 224; offsetO, calldata]
mul               // [calldata >> 224 * offsetO, calldata]

jumpi             // jump to calldata * offsetO if calldata is not 0  - []

//calldata is 0:
caller           // [caller;]
push1 0x10       // - offsetEnd  // [offsetEnd; caller;]
jump             // [caller;]

// calldata is 1:
jumpdest         // - offsetO 
origin           // [origin;]

jumpdest // - offsetEnd [caller/origin;]

returndatasize // [0x0; caller/origin]
mstore // store caller/origin at 0x0 []

// return 32 bytes from 0x0 memory
PUSH1 0x20
returndatasize
return
*/