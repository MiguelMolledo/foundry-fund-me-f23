// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
// third party imports
import {Test, console} from "forge-std/Test.sol";

// in-house imports
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address[] public USERS;
    address OWNER = makeAddr("user");

    uint256 constant SEND_VALUE = 0.1 ether; // 0.1e17
    uint256 constant STARTING_BALANCE = 50 ether; // 0.1e17
    uint256 constant GAS_PRICE = 1;

    function uint2str(
        uint _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function setUp() external {
        setUpUsers();
        DeployFundMe deployFundme = new DeployFundMe();
        fundMe = deployFundme.run();
    }

    function setUpUsers() internal {
        uint160 addressesCount = 10;

        for (uint160 i = 0; i < addressesCount; i++) {
            string memory user = string(abi.encodePacked("USER_", uint2str(i)));
            address newUserAddress = makeAddr(user);
            vm.deal(newUserAddress, STARTING_BALANCE);
            USERS.push(newUserAddress);
        }
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsSender() public {
        console.log("i_owner: %s", address(fundMe.getOwner()));
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccuarate() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        // execute fund me with a payable argument
        // this payable argument needs to be les thant 5 usd or 5 * 10e8
        // We need to expect a revert here
        // vm.expectRevert(Specific rever);
        // fundMe.fund{value: 3 * 10e8}(); should fail
        vm.prank(USERS[0]);
        vm.expectRevert();
        fundMe.fund{value: 3 * 10e8}();
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFoundedDataStructure() public {
        // uint256 quantityFounded = fundMe.addressToAmountFunded(address(this));

        vm.prank(USERS[0]);
        fundMe.fund{value: SEND_VALUE}();
        assertEq(SEND_VALUE == fundMe.getAddressToAmountFunded(USERS[0]), true);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USERS[0]);
        fundMe.fund{value: SEND_VALUE}();
        address funderAddress = fundMe.getFunder(0);
        assertEq(funderAddress == USERS[0], true);
    }

    modifier funded_all() {
        for (uint i = 0; i < USERS.length; i++) {
            vm.prank(USERS[i]);
            fundMe.fund{value: SEND_VALUE}();
        }
        _;
    }
    modifier funded_1() {
        vm.prank(USERS[0]);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testWithDrawFundsFailsWithNoOwner() public funded_1 {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithDrawWithSingleFunder() public funded_1 {
        // arrange
        // prepare funds
        // record previous funds

        uint256 startingOwnerBalance = fundMe.getOwnerBalance();
        uint256 startingFundMeBalance = fundMe.getContractBalance();
        // act
        // extract funds
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 endingOwnerBalance = fundMe.getOwnerBalance();
        // assert
        // check contract balance

        // check owner final balance
        assertEq(
            endingOwnerBalance == startingOwnerBalance + startingFundMeBalance,
            true
        );

        // Check funds balance
        uint256 fundsBalanace = fundMe.getContractBalance();
        assertEq(fundsBalanace, 0);
    }

    function testWithDrawWithMultipleFunders() public funded_all {
        // arrange
        // prepare funds
        // record previous funds
        // uint256 gasStart = gasleft();

        uint256 startingOwnerBalance = fundMe.getOwnerBalance();
        uint256 startingFundMeBalance = fundMe.getContractBalance();
        // act
        // extract funds
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwnerBalance();
        // assert
        // check contract balance

        // check owner final balance
        assertEq(
            endingOwnerBalance == startingOwnerBalance + startingFundMeBalance,
            true
        );
        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // Check funds balance
        uint256 fundsBalanace = fundMe.getContractBalance();
        assertEq(fundsBalanace, 0);
    }
}
