// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// interfaces
import {IWstETH} from "./interfaces/IWstETH.sol";
import {IStETH} from "./interfaces/IStETH.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {IWithdrawalQueueERC721} from "./interfaces/IWithdrawalQueueERC721.sol";

// libs
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {LibArray} from "./LibArray.sol";

// inherits
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "forge-std/Test.sol";

IWETH9 constant WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

contract FriendlyStETH is Ownable, ERC4626 {
    uint256 constant WAD = 1e18;

    IStETH public constant stETH = IStETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

    IWstETH public constant wstETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    IWithdrawalQueueERC721 public constant unstEthNft =
        IWithdrawalQueueERC721(0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1); // prettier-ignore

    uint256 constant WITHDRAW_CHUNK_SIZE = 100 ether;
    uint256 constant MIN_BUFFER_PERCENTAGE = 0.05 * 1e18; // 5%

    /// @notice Desired percentage of total assets held as buffer (initially set to 10%)
    uint256 public bufferPercentage = 0.1 * 1e18; // 10%

    /// @notice Maximum size of buffer in ETH (initially set to 100 ETH)
    /// Prioritizes maxBufferSize over bufferPercentage
    uint256 public maxBufferSize = 100 ether;

    /// @notice Total amount of stETH currently pending for withdrawal
    uint256 public pendingWithdrawalStEthAmount;

    mapping(uint256 => bool) public requestIdsIssuedBySelf;

    event RequestWithdrawals(uint256[] requestIds);
    event SetBufferPercentage(uint256 bufferPercentage);
    event SetMaxBufferSize(uint256 maxBufferSize);

    error InvalidMaxBufferSize();
    error InvalidBufferPercentage();
    error WithdrawalRequestNotIssuedByThisContract(uint256 requestId);

    receive() external payable {}

    constructor(address owner) ERC20("Friendly StETH", "FSTETH") ERC4626(WETH) {
        stETH.approve(address(unstEthNft), type(uint256).max);

        transferOwnership(owner);
    }

    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        uint256 assets = _convertToAssets(balanceOf(owner), Math.Rounding.Down);
        uint256 upperLimit = WETH.balanceOf(address(this));
        return Math.min(assets, upperLimit);
    }

    function maxRedeem(address owner) public view virtual override returns (uint256) {
        uint256 bal = balanceOf(owner);
        uint256 upperLimit = _convertToShares(WETH.balanceOf(address(this)), Math.Rounding.Down);
        return Math.min(bal, upperLimit);
    }

    function totalAssets() public view virtual override returns (uint256) {
        uint256 stEthBal = stETH.balanceOf(address(this));
        uint256 wethBal = WETH.balanceOf(address(this));
        // pending withdrawals are not included in the stEth balance
        // because it is transferred to the Lido withdrawal queue contract

        // NOTE: If there was some massive loss for Lido on the Beacon Chain side,
        // pending stEth withdrawals could be worth less than 1:1 conversion to eth.
        // In that case, this pending withdrawal amount would report a higher value more than it is worth.
        // This is because that if ruqest withdrawals, they don't receive rewards but still take risks during withdrawal.
        return wethBal + stEthBal + pendingWithdrawalStEthAmount;
    }

    /// @notice get total assets and buffer balances
    /// @return total assets: sum of stETH, WETH, and pending withdrawal stETH
    /// @return buffer balance: WETH balance + pending withdrawal stETH
    /// @return immediate withdrawable balance: WETH balance
    function getTotalAssetsAndBufferBalances() public view returns (uint256, uint256, uint256) {
        uint256 _wethBal = WETH.balanceOf(address(this));
        uint256 _stEthBal = stETH.balanceOf(address(this));
        uint256 currentBufferBalance = _wethBal + pendingWithdrawalStEthAmount;
        return (_stEthBal + currentBufferBalance, currentBufferBalance, _wethBal);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Mutative functions
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice process deposits
    /// @dev Deposit to Lido and mint stETH
    /// if we have more weth than the buffer size, we will deposit the difference
    /// but if we don't have enough weth to deposit, we will deposit all the weth we have
    function submit() external returns (uint256) {
        (
            uint256 _totalAssets,
            uint256 _currentBufferBalance,
            uint256 wethAvailable
        ) = getTotalAssetsAndBufferBalances();
        uint256 desiredBufferBalance = Math.min(maxBufferSize, (_totalAssets * bufferPercentage) / WAD);

        if (desiredBufferBalance >= _currentBufferBalance) {
            // do nothing
            return 0;
        }
        // if we have excess weth available, deposit it

        unchecked {
            uint256 depositAmount = _currentBufferBalance - desiredBufferBalance;
            if (depositAmount >= wethAvailable) {
                // skip deposits because we need to left some weth for immediate withdrawals.
                // we're waiting for withdrawals to complete
                return 0;
            }

            WETH.withdraw(depositAmount);
            return stETH.submit{value: depositAmount}(address(0));
        }
    }

    /// @notice request withdrawal to Lido to make a buffer for immediate withdrawals
    /// @dev According to Lido doc: https://docs.lido.fi/contracts/withdrawal-queue-erc721#request
    /// The amount of ether that will be withdrawn is limited to the number of stETH tokens transferred to this contract at the moment of request.
    /// So, the user will not receive the rewards for the period of time while their tokens stay in the queue.
    ///
    /// if we have less weth than the buffer size, we will request the difference
    /// if we have more weth than the buffer size, we don't need to request
    /// request is chunked into 100 stETH per request
    /// @return withdrawAmount stEth amount transferred to Lido
    /// @return requestIds requestIds issued by Lido
    function requestWithdrawalUpToBuffer() external returns (uint256, uint256[] memory) {
        (uint256 _totalAssets, uint256 _currentBufferBalance, ) = getTotalAssetsAndBufferBalances();

        uint256 desiredBufferBalance = Math.min(maxBufferSize, (_totalAssets * bufferPercentage) / WAD);

        if (_currentBufferBalance >= desiredBufferBalance) {
            // do nothing
            return (0, new uint256[](0));
        }

        unchecked {
            uint256 withdrawAmount = desiredBufferBalance - _currentBufferBalance; // no underflow because of if statement above
            uint256 fullChunks = withdrawAmount / WITHDRAW_CHUNK_SIZE;
            uint256 remaining = withdrawAmount % WITHDRAW_CHUNK_SIZE;
            // Initialize an array
            // oveflow would cause memory to bloated and unlikely to happen
            uint256[] memory amounts = LibArray.fill(fullChunks + (remaining != 0 ? 1 : 0), WITHDRAW_CHUNK_SIZE);
            if (remaining != 0) {
                amounts[fullChunks] = remaining;
            }

            // pending amount and withdrawAmount are capped at total stETH supply. next line wouldn't overflow
            pendingWithdrawalStEthAmount += withdrawAmount;
            // request withdrawals
            // transfer stEth to unstEthNft
            uint256[] memory requestIds = unstEthNft.requestWithdrawals(amounts, address(this));
            uint256 length = requestIds.length;
            for (uint256 i = 0; i < length; ++i) {
                requestIdsIssuedBySelf[requestIds[i]] = true;
            }
            emit RequestWithdrawals(requestIds);
            return (withdrawAmount, requestIds);
        }
    }

    /// @notice Claims the withdrawals
    /// @param requestIds valid requestIds
    /// @param hints valid hints
    function claimWithdrawals(uint256[] calldata requestIds, uint256[] calldata hints) external returns (uint256) {
        // optimistically assume all requestIds are valid and successful
        // request must be issued by this contract itself.
        // this is required because someone can transfer unstEthNft to this contract and call claimWithdrawals
        // and pendingWithdrawalStEthAmount will behave incorrectly
        uint256 length = requestIds.length;
        for (uint256 i = 0; i < length; ) {
            if (!requestIdsIssuedBySelf[requestIds[i]]) revert WithdrawalRequestNotIssuedByThisContract(requestIds[i]);
            unchecked {
                ++i;
            }
        }
        // optimstically sum pending stETH.
        IWithdrawalQueueERC721.WithdrawalRequestStatus[] memory statuses = unstEthNft.getWithdrawalStatus(requestIds);
        pendingWithdrawalStEthAmount -= sumWithdrawnStEth(statuses); // @audit stETH 1-2 wei rounding error

        // claim withdrawals
        // non-reentrant
        uint256 ethBal = address(this).balance;
        unstEthNft.claimWithdrawals(requestIds, hints);
        uint256 claimedEth = address(this).balance - ethBal;

        // wrap eth
        WETH.deposit{value: claimedEth}();

        return claimedEth;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Util
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// Sums the amount of stETH withdrawn
    function sumWithdrawnStEth(
        IWithdrawalQueueERC721.WithdrawalRequestStatus[] memory _statuses
    ) internal pure returns (uint256 total) {
        uint256 len = _statuses.length;
        for (uint256 i = 0; i < len; ) {
            total += _statuses[i].amountOfStETH;
            unchecked {
                ++i;
            }
        }
        return total;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Protected functions
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice sets the max buffer size
    /// @param _maxBufferSize new max buffer size
    function setMaxBufferSize(uint256 _maxBufferSize) external onlyOwner {
        if (_maxBufferSize == 0 && pendingWithdrawalStEthAmount > maxBufferSize) {
            revert InvalidMaxBufferSize();
        }
        maxBufferSize = _maxBufferSize;
        emit SetMaxBufferSize(_maxBufferSize);
    }

    function setBufferPercentage(uint256 _bufferPercentage) external onlyOwner {
        if (_bufferPercentage < MIN_BUFFER_PERCENTAGE || _bufferPercentage >= WAD) {
            revert InvalidBufferPercentage();
        }
        bufferPercentage = _bufferPercentage;
        emit SetBufferPercentage(_bufferPercentage);
    }
}
