// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Base.t.sol";

contract BufferPercentageTest is BaseTest {
    function test_RevertWhen_NonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        fstETH.setBufferPercentage(0.15 * 1e18);
    }

    function test_RevertWhen_PercentageLtMin() public {
        vm.expectRevert(FriendlyStETH.InvalidBufferPercentage.selector);
        vm.prank(owner);
        fstETH.setBufferPercentage(10);
    }

    function test_RevertWhen_PercentageGt100() public {
        vm.expectRevert(FriendlyStETH.InvalidBufferPercentage.selector);
        vm.prank(owner);
        fstETH.setBufferPercentage(1e18);
    }

    function test_SetBufferPercentage() public {
        vm.prank(owner);
        fstETH.setBufferPercentage(0.15 * 1e18);
        assertEq(fstETH.bufferPercentage(), 0.15 * 1e18);
    }
}
