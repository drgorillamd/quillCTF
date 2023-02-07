// SPDX-License-Identifier: None
pragma solidity 0.8.7;

import { Test } from "forge-std/Test.sol";
import { IBoolGiver, TrueXOR  } from "../src/TrueXor.sol";

/**
 * @title   Answer to the TrueXor Challenge
 * @notice  Use the gas passed to the call to flip the bool returned in
 *          different state (and bypass the tx.origin==msg.sender by using
 *          a delegate call originating from a first contract, this forge test
 *          in this case)
 * @author  DrGorilla.eth
 */
contract TrueXORTest is Test {
    address _contract;

    function setUp() public {
        _contract = address(new TrueXOR());
    }

    function testTrueXor() public {
        address _solution = address(new Hack());

        (bool _success, ) = _contract.delegatecall
            {gas: 1000 + 10000}
            (abi.encodeWithSelector(TrueXOR.callMe.selector, _solution));

        assertTrue(_success);
    }
}

contract Hack is IBoolGiver {
    function giveBool() external override view returns(bool) {
        uint256 _gasMessage = 10000; // are we before or after the first call?
        bool _firstCall = gasleft() > _gasMessage;
        return _firstCall;
    }

}