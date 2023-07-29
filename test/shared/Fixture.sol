// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "../Base.t.sol";

contract Fixture is BaseTest {
    function setUp() public virtual override {
        super.setUp();
        // fund 80 stETH and 20 weth
        // set buffer percentage to 20%
        // current buffer size is exactly equal to desired buffer size
        uint256 bufferPercentage = 0.2 * 1e18;

        deal(address(WETH), address(fstETH), 20 ether, false);
        stETH.submit{value: 80 ether}(address(0));
        uint256 share = stETH.sharesOf(address(this));
        stETH.transferShares(address(fstETH), share);

        // disable max buffer size
        vm.prank(owner);
        fstETH.setMaxBufferSize(10000 ether);
        vm.prank(owner);
        fstETH.setBufferPercentage(bufferPercentage);
    }

    modifier whenEnoughBufferBalance() virtual {
        vm.prank(owner);
        fstETH.setBufferPercentage(0.1 * 1e18);
        _;
    }

    modifier whenNotEnoughBufferBalance() virtual {
        vm.prank(owner);
        fstETH.setBufferPercentage(0.3 * 1e18);
        _;
    }
}
