// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import {IWstETH} from "src/interfaces/IWstETH.sol";
import {IStETH} from "src/interfaces/IStETH.sol";
import {IWithdrawalQueueERC721} from "src/interfaces/IWithdrawalQueueERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "src/FstETH.sol";

IStETH constant stETH = IStETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

IWstETH constant wstETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

IWithdrawalQueueERC721 constant unstEthNft = IWithdrawalQueueERC721(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1); // prettier-ignore

contract Util is TestBase {
    using stdStorage for StdStorage;

    function _overwriteWithOneKey(address account, string memory sig, address key, uint256 value) internal {
        stdstore.target(account).sig(sig).with_key(key).checked_write(value);
    }

    function _approve(IERC20 token, address _owner, address spender, uint256 value) internal {
        vm.startPrank(_owner);
        token.approve(spender, 0);
        token.approve(spender, value);
        vm.stopPrank();
    }
}

contract BaseTest is Test, Util {
    uint256 WAD = 10 ** 18;
    FriendlyStETH fstETH;
    address owner;

    function setUp() public virtual {
        vm.label(address(WETH), "WETH");
        vm.label(address(stETH), "stETH");
        vm.label(address(wstETH), "wstETH");
        vm.label(address(unstEthNft), "unsteth");

        vm.createSelectFork("mainnet", 17790000);

        owner = makeAddr("owner");
        fstETH = new FriendlyStETH(owner);
    }

    /// @notice used to fund stETH to a fuzz input address.
    /// @dev if token is stETH, then stake ETH to get stETH.
    ///      stETH balance of `to` will be 1 wei greater than or equal to `give`.
    function deal(address token, address to, uint256 give, bool adjust) internal virtual override {
        // deal doesn't support stETH. this is because stETH uses internal accounting system.
        if (token == address(stETH)) {
            if (adjust) console2.log("deal stETH doesn't support `adjust=true`. just ignore it.");
            if (give == 0) return; // zero deposit is not allowed by StETH contract.
            // +2 is to make sure the balance is greater than or equal to `give`
            uint256 shares = ((give + 2) * stETH.getTotalShares()) / stETH.getTotalPooledEther();
            _overwriteWithOneKey(address(stETH), "sharesOf(address)", to, shares);
        } else {
            super.deal(token, to, give, adjust);
        }
    }

    function assertBufferBalance() internal {
        uint256 currentBufferBal = currentBufferBalance();
        assertEq(getDesiredBufferBalance(), currentBufferBal, "equal to desired buffer balance");
    }

    function currentBufferBalance() public view returns (uint256) {
        uint256 wethBal = WETH.balanceOf(address(fstETH));
        return fstETH.pendingWithdrawalStEthAmount() + wethBal;
    }

    function getDesiredBufferBalance() public view returns (uint256) {
        // (uint256 _totalAssets, uint currentBufferBal, ) = fstETH.getTotalAssetsAndBufferBalances();
        // return (Math.min(fstETH.maxBufferSize(), (_totalAssets * fstETH.bufferPercentage()) / 1e18), currentBufferBal);
        uint256 totalAssets = fstETH.totalAssets();
        return Math.min(fstETH.maxBufferSize(), (totalAssets * fstETH.bufferPercentage()) / 1e18);
    }
}
