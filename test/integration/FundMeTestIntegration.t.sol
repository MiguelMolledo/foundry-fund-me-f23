// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
// third party imports
import {Test, console} from "forge-std/Test.sol";

// in-house imports
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;
    address OWNER = makeAddr("user");
    address USER = makeAddr("user");

    uint256 constant SEND_VALUE = 0.1 ether; // 0.1e17
    uint256 constant STARTING_BALANCE = 50 ether; // 0.1e17
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundme = new DeployFundMe();
        fundMe = deployFundme.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        // WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        // withdrawFundMe.withdrawFundMe(address(withdrawFundMe));

        // assert(address(fundFundMe).balance == 0);
    }
}
