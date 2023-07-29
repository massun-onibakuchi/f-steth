// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Fixture.sol";

contract ClaimTest is Fixture {
    function _claimWithdrawals(uint256[] memory requestIds, uint256[] memory hints) internal returns (uint256) {
        return fstETH.claimWithdrawals(requestIds, hints);
    }
}
