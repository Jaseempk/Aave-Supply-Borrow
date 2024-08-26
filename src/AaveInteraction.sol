//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "aave-v3-core/contracts/misc/interfaces/IWETH.sol";
import {IPool} from "aave-v3-core/contracts/interfaces/IPool.sol";
import {console} from "forge-std/console.sol";

contract AaveInteraction {
    //error
    error AI__InsufficientEthSupply();

    event HealthfactorUpdated(address user, uint256 _healthFactor);

    IPool immutable aavePool;
    IWETH immutable weth;
    IERC20 immutable usdcToken;

    constructor(address _aavePool, address _usdcToken, address _weth) {
        aavePool = IPool(_aavePool);
        weth = IWETH(_weth);
        usdcToken = IERC20(_usdcToken);
    }

    function supplyNBorrow(uint256 _usdcAmount) external payable {
        if (msg.value < 1 ether) revert AI__InsufficientEthSupply();

        console.log("WETH address:", address(weth));

        try weth.deposit{value: 1 ether}() {} catch Error(
            string memory reason
        ) {
            console.log("WETH deposit failed:", reason);
            revert(reason);
        } catch {
            console.log("WETH deposit failed with no reason");
            revert("WETH deposit failed");
        }
        weth.approve(address(aavePool), msg.value);
        aavePool.supply(address(weth), msg.value, address(this), 0);

        aavePool.borrow(address(usdcToken), _usdcAmount, 2, 0, address(this));
        (, , , , , uint256 healthFactor) = aavePool.getUserAccountData(
            address(this)
        );

        uint256 readableHealthFactor = healthFactor / 1e25;

        emit HealthfactorUpdated(address(this), readableHealthFactor);
    }

    receive() external payable {}
}
