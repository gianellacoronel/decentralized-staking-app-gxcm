// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
    event Stake(address indexed sender, uint256 amount);

    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw = false;

    function stake() public payable {
        //Update user balance
        balances[msg.sender] += msg.value;
        //Emit the event
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public {
        //Get a variable with the balance of the contract to make the comparisons
        uint256 contractBalance = address(this).balance;

        //Check if deadline has passed
        require(block.timestamp >= deadline, "Deadline has not passed yet");
        if (contractBalance >= threshold) {
            exampleExternalContract.complete{ value: contractBalance }();
        } else {
            openForWithdraw = true;
            withdraw();
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public {
        //get the amount of Ether the sender stake in the contract
        uint256 amount = balances[msg.sender];
        require(amount > 0, "You have no balance to withdraw");
        require(block.timestamp >= deadline, "Deadline not reached");
        require(address(this).balance < threshold, "Threshold was met, cannot withdraw");

        //send all Ether to msg.sender
        (bool success, ) = msg.sender.call{ value: amount }("");

        //reset data of mapping balances
        require(success, "Withdraw failed");
        balances[msg.sender] = 0;
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}
