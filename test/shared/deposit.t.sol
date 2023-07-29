// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Fixture} from "./Fixture.sol";
import "../Base.t.sol";

contract DepositTest is Fixture {
    using stdStorage for StdStorage;

    uint256 initialBalance;

    function setUp() public override {
        BaseTest.setUp();
        // set buffer percentage to 20%
        uint256 bufferPercentage = 0.2 * 1e18;

        // disable max buffer size
        vm.prank(owner);
        fstETH.setMaxBufferSize(10000 ether);
        vm.prank(owner);
        fstETH.setBufferPercentage(bufferPercentage);

        initialBalance = 20 ether;
        // fund 80 stETH and 20 weth to this contract
        deal(address(stETH), address(this), 80 ether, false);
        deal(address(WETH), address(this), initialBalance, false);
    }

    modifier whenNonPendingWithdrawals() {
        _;
    }

    modifier whenNonFinalizedWithdrawals() {
        _;
    }

    function _deposit(uint256 assets, address receipt, address sender) internal returns (uint256) {
        _approve(WETH, sender, address(fstETH), assets);
        vm.prank(sender);
        return fstETH.deposit(assets, receipt);
    }
}
