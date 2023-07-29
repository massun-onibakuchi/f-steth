// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Fixture.sol";

contract ClaimTest is Fixture {
    modifier whenNotEnoughBufferBalance() {
        vm.prank(owner);
        fstETH.setBufferPercentage(0.3 * 1e18);
        _;
    }

    function _claimWithdrawals(uint256[] memory requestIds, uint256[] memory hints) internal returns (uint256) {
        return fstETH.claimWithdrawals(requestIds, hints);
    }
}
