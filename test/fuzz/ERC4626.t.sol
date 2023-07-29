// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IWithdrawalQueueERC721} from "src/interfaces/IWithdrawalQueueERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC4626Test} from "erc4626-tests/ERC4626.test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {StETHMock} from "../mocks/StETHMock.sol";
import {WithdrawalQueueERC721Mock} from "../mocks/WithdrawalQueueERC721Mock.sol";

import "../Base.t.sol";

contract WETHMock is ERC20 {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    constructor() ERC20("Wrapped Ether", "WETH") {}

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function mint(address account, uint256 value) external {
        _mint(account, value);
        vm.deal(address(this), totalSupply());
        vm.deal(msg.sender, msg.sender.balance + value);
    }

    function burn(address from, uint256 value) external {
        _burn(from, value);
        vm.deal(address(this), totalSupply());
        vm.deal(msg.sender, msg.sender.balance - value);
    }

    function withdraw(uint256 amount) public {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}

contract ERC4626StdTest is BaseTest, ERC4626Test {
    function setUp() public override(BaseTest, ERC4626Test) {
        vm.label(address(WETH), "WETH");
        vm.label(address(stETH), "stETH");
        vm.label(address(unstEthNft), "unsteth");

        vm.allowCheatcodes(address(WETH));
        vm.allowCheatcodes(address(unstEthNft));
        // override code with mock contract
        // because it takes too much time and consumes a lot resources when running tests on forked mainnet
        deployCodeTo("ERC4626.t.sol:WETHMock", address(WETH));
        deployCodeTo("StETHMock.sol", address(stETH));
        deployCodeTo("WithdrawalQueueERC721Mock.sol", address(unstEthNft));

        owner = makeAddr("owner");
        fstETH = new FriendlyStETH(owner);

        _underlying_ = address(WETH);
        _vault_ = address(fstETH);
        _delta_ = 10;
        _vaultMayBeEmpty = true;
        _unlimitedAmount = false;

        // disable max buffer size
        vm.prank(owner);
        fstETH.setMaxBufferSize(100000000 ether);
        vm.prank(owner);
        fstETH.setBufferPercentage(0.2 * 1e18);
    }

    // setup initial vault state as follows:
    //
    // totalAssets == sum(init.share) + init.yield
    // totalShares == sum(init.share)
    //
    // init.user[i]'s assets == init.asset[i]
    // init.user[i]'s shares == init.share[i]
    function setUpVault(Init memory init) public override {
        for (uint256 i = 0; i < N; i++) {
            init.asset[i] = bound(init.asset[i], 0, 10_000_000 * WAD);
            init.share[i] = bound(init.share[i], 0, 10_000_000 * WAD);
        }

        super.setUpVault(init);
    }

    // setup initial yield
    function setUpYield(Init memory init) public override {
        // deposit some WETH to Lido
        fstETH.submit();
        if (init.yield >= 0) {
            // gain
            try StETHMock(address(stETH)).mint(_vault_, uint256(init.yield)) {} catch {
                vm.assume(false);
            }
        } else {
            // loss
            vm.assume(init.yield > type(int256).min); // avoid overflow in conversion
            uint256 loss = uint256(-1 * init.yield);
            try StETHMock(address(stETH)).slash(_vault_, loss) {} catch {
                vm.assume(false);
            }
        }
    }

    function deal(address token, address to, uint256 give, bool adjust) internal override(BaseTest, StdCheats) {
        BaseTest.deal(token, to, give, adjust);
    }
}
