// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IDataProvider.sol";
import { IERC20 } from "./IERC20.sol";

contract TotalSupplyProvider is IDataProvider {
    IERC20 public token;

    constructor(IERC20 _token) {
        token = _token;
    }

    function getLabel() external view override returns (string memory) {
        return "Total Supply";
    }

    function getMetricData(address tokenA) external view override returns (uint256) {
        require(tokenA == address(token), "INVALID_TOKEN");
        return token.totalSupply();
    }

    function getTags() external view override returns (string[] memory) {
        string[] memory tags = new string[](1);
        tags[0] = "total-supply";
        return tags;
    }

    function getDataTimestamp() external view override returns (uint256) {
        return block.timestamp;
    }
}
