// SPDX-License-Identifier: None
pragma solidity 0.8.7;

import { Test } from "forge-std/Test.sol";
import { Confidential } from "../src/Confidential.sol";

/**
 * @title   Answer to the Confidential Challenge
 * @notice  Use cast to retrieve the value of the private storage variables, then
 *          test the solution via this Forge test
 *          cast storage 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 2 --rpc-url $GOERLI
 *          cast storage 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 7 --rpc-url $GOERLI
 * @author  DrGorilla.eth
 */
contract ConfidentialTest is Test {
    Confidential _contract;

    // The key retrieved from cast
    bytes32 keyAlice = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    bytes32 keyBob = 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6;

    function setUp() public {
        // Fork Goerli, to use the correct instance
        vm.createSelectFork('https://rpc.ankr.com/eth_goerli');
        _contract = Confidential(0xf8E9327E38Ceb39B1Ec3D26F5Fad09E426888E66);
    }

    function testHashes() public {
        // Compute the key/data hashes
        bytes32 _aliceHash = _contract.hash(keyAlice, _contract.ALICE_DATA());
        bytes32 _bobHash = _contract.hash(keyBob, _contract.BOB_DATA());

        // Check: are the hashes correct?
        assertTrue(_contract.checkthehash(_contract.hash(_aliceHash, _bobHash)));
    }
}