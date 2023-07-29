// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../shared/Fixture.sol";

import "forge-std/Test.sol";

contract SubmitUnitTest is Fixture {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
    }

    modifier whenNonPendingWithdrawals() {
        _;
    }

    modifier whenNonFinalizedWithdrawals() {
        _;
    }

    modifier increaseBufferPercentage() {
        vm.prank(owner);
        fstETH.setBufferPercentage(0.5 * 1e18);
        _;
    }

    modifier decreaseBufferPercentage() {
        vm.prank(owner);
        fstETH.setBufferPercentage(0.05 * 1e18);
        _;
    }

    function test_WhenLessThanDesiredBuffer()
        public
        whenNonPendingWithdrawals
        whenNonFinalizedWithdrawals
        increaseBufferPercentage
    {
        //execution
        uint256 minted = fstETH.submit();
        //assert
        assertEq(minted, 0, "shoud not be minted");
    }

    function test_WhenMoreThanDesiredBuffer_EnoughEthAvailable()
        public
        whenNonPendingWithdrawals
        whenNonFinalizedWithdrawals
        decreaseBufferPercentage
    {
        //execution
        uint256 minted = fstETH.submit();
        assertGt(minted, 0, "minted");
        assertBufferBalance();
    }

    modifier whenPendingWithdrawals() {
        // overwrite storage value
        stdstore.target(address(fstETH)).sig(fstETH.pendingWithdrawalStEthAmount.selector).checked_write(20 ether);
        _;
    }

    function test_WhenMoreThanDesiredBuffer_NotEnoughEthAvailable()
        public
        whenPendingWithdrawals
        whenNonFinalizedWithdrawals
        decreaseBufferPercentage
    {
        //execution
        uint256 minted = fstETH.submit();
        assertEq(minted, 0, "should not be minted");
    }
}
