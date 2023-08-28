// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibArray {
    function fill(uint256 length, uint256 value) internal pure returns (uint256[] memory arr) {
        arr = new uint256[](length);
        for (uint256 i = 0; i < length;) {
            arr[i] = value;
            unchecked {
                ++i;
            }
        }
    }
}
