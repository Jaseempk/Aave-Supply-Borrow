//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AaveInteraction} from "src/AaveInteraction.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "aave-v3-core/contracts/misc/interfaces/IWETH.sol";
import {IPool} from "aave-v3-core/contracts/interfaces/IPool.sol";
import {console} from "forge-std/console.sol";

contract AaveInteractionTest is Test {
    AaveInteraction public aaveInteraction;
    IPool public aavePool;
    IWETH public weth;
    IERC20 public usdcToken;
    uint256 mainnetFork;

    // Mainnet addresses (for forking)
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address constant USDC_WHALE = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;
    address constant ETH_WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC;

    function setUp() public {
        // Fork Ethereum mainnet
        // mainnetFork = vm.createSelectFork(vm.envString("ETH_RPC_URL"));

        // Deploy the contract
        aaveInteraction = new AaveInteraction(AAVE_POOL, USDC,WETH);
        aavePool = IPool(AAVE_POOL);
        weth = IWETH(WETH);
        usdcToken = IERC20(USDC);
    }

    function test_depositAndBorrow() public {
        vm.startPrank(ETH_WHALE);
        payable(address(aaveInteraction)).transfer(2 ether);
        vm.stopPrank();

        // Impersonate USDC whale to approve spending for our contract
        vm.startPrank(USDC_WHALE);
        IERC20(USDC).approve(address(aaveInteraction), 1000 * 1e6);
        vm.stopPrank();

        // Record balances before
        uint256 contractEthBefore = address(aaveInteraction).balance;
        uint256 contractUsdcBefore = IERC20(USDC).balanceOf(
            address(aaveInteraction)
        );

        // Call the function
        aaveInteraction.supplyNBorrow{value: 1 ether}(1000 * 1e6); // 1000 USDC

        // Record balances after
        uint256 contractEthAfter = address(aaveInteraction).balance;
        uint256 contractUsdcAfter = IERC20(USDC).balanceOf(
            address(aaveInteraction)
        );

        // Assertions
        assertEq(
            contractEthBefore - contractEthAfter,
            1 ether,
            "Should have supplied 1 ETH"
        );
        assertEq(
            contractUsdcAfter - contractUsdcBefore,
            1000 * 1e6,
            "Should have borrowed 1000 USDC"
        );
    }
}
