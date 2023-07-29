// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Base.t.sol";

contract BufferSizeTest is BaseTest {
    function test_RevertWhen_MaxBufferSize_Zero() public {}

    function test_RevertWhen_MaxBufferSize_PendingWithdrawalSize() public {}

    function test_RevertWhen_NonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        fstETH.setMaxBufferSize(200 ether);
    }

    function test_SetMaxBufferSize() public {
        vm.prank(owner);
        fstETH.setMaxBufferSize(200 ether);
        assertEq(fstETH.maxBufferSize(), 200 ether);
    }
}
