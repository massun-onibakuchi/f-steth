// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Base.t.sol";
import "../shared/deposit.t.sol";

contract DepositIntegrationTest is DepositTest {
// modifier rebaseStETHPositive() {
//     bytes32 STETH_BUFFERED_ETHER_POSITION_SLOT = keccak256("lido.Lido.bufferedEther");
//     uint256 bufferedEth = stETH.getBufferedEther();
//     deal(address(stETH), address(stETH).balance + 1 ether);
//     vm.store(address(stETH), STETH_BUFFERED_ETHER_POSITION_SLOT, bytes32(bufferedEth + 1 ether));
//     uint256 bufferedEthAfter = stETH.getBufferedEther();
//     _;
// }
}
