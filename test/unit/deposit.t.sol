// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Base.t.sol";
import "../shared/deposit.t.sol";

contract DepositUnitTest is DepositTest {
    modifier whenTotalSupplyIsZero() {
        require(fstETH.totalSupply() == 0, "total supply is not zero");
        _;
    }

    function test_RevertWhen_NoSharesMinted() public whenTotalSupplyIsZero {
        // Note: when totalSupply is zero and someone donates eth,
        // the contract will not mint any shares for depositors.
        // to mitigate this, we revert if nothing are minted.
        deal(address(WETH), address(fstETH), 100 ether, false);
        _approve(WETH, address(this), address(fstETH), type(uint256).max);

        uint256 amount = initialBalance;
        vm.expectRevert(FriendlyStETH.ZeroShares.selector);
        fstETH.deposit(amount, address(this));
    }

    modifier whenEnoughBufferBalance() override {
        _;
    }

    modifier whenNotEnoughBufferBalance() override {
        _;
    }

    function test_Deposit() public whenEnoughBufferBalance whenNonPendingWithdrawals whenNonFinalizedWithdrawals {
        uint256 amount = initialBalance;
        uint256 shares = fstETH.previewDeposit(amount);
        uint256 minted = _deposit(amount, address(this), address(this));
        //assert
        assertGt(minted, 0, "gt zero");
        assertEq(fstETH.balanceOf(address(this)), minted, "bal");
        assertEq(shares, minted, "shares");
        assertEq(shares, fstETH.previewDeposit(amount), "preview deposit before and after");
    }

    function test_Deposits() public whenEnoughBufferBalance whenNonPendingWithdrawals whenNonFinalizedWithdrawals {
        uint256 amount = initialBalance;
        uint256 minted = _deposit(amount, address(this), address(this));
        // profit
        deal(address(stETH), address(fstETH), 0.001 ether, false);
        // second deposit
        deal(address(WETH), address(0xcafe), amount, false);
        uint256 minted2 = _deposit(amount, address(this), address(0xcafe));
        assertLt(minted2, minted, "should be less than previous deposit");
    }
}
