// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Fixture.sol";

import "forge-std/Test.sol";

abstract contract RequestTest is Fixture {
    using stdStorage for StdStorage;

    function _requestWithdrawal() internal returns (uint256 withdrawAmount) {
        uint256 before = fstETH.pendingWithdrawalStEthAmount();
        (withdrawAmount,) = fstETH.requestWithdrawalUpToBuffer();
        assertApproxEqAbs(fstETH.pendingWithdrawalStEthAmount(), before + withdrawAmount, 2, "pending withdrawal delta");
    }
}
