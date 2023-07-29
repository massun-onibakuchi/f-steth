// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Fixture} from "./Fixture.sol";
import "../Base.t.sol";

contract DepositTest is Fixture {
    using stdStorage for StdStorage;

    uint256 initialBalance;

    function setUp() public override {
        super.setUp();

        initialBalance = 10 ether;
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
