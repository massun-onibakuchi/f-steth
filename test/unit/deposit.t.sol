// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Base.t.sol";
import "../shared/deposit.t.sol";

contract DepositUnitTest is DepositTest {
    function test_RevertWhen_MaxDeposit() public whenNonPendingWithdrawals whenNonFinalizedWithdrawals {
        // vm.mockCall(address(fstETH), abi.encodeCall(ERC4626.maxDeposit, address(this)), abi.encode(10));
        // vm.expectRevert("ERC4626: deposit more than max");
        // fstETH.deposit(1000, address(this));
    }

    function test_Deposit() public whenNonPendingWithdrawals whenNonFinalizedWithdrawals {
        uint256 amount = initialBalance;
        uint256 shares = fstETH.previewDeposit(amount);
        uint256 minted = _deposit(amount, address(this), address(this));
        //assert
        assertGt(minted, 0, "gt zero");
        assertEq(fstETH.balanceOf(address(this)), minted, "bal");
        assertEq(shares, minted, "shares");
        assertEq(shares, fstETH.previewDeposit(amount), "preview deposit before and after");
    }

    function test_Deposits() public whenNonPendingWithdrawals whenNonFinalizedWithdrawals {
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
