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
		return
			string(
				abi.encodePacked("totalSupply", IERC20(address(token)).name())
			);
	}

	function getMetricData(
		address tokenA
	) external view override returns (uint256) {
		require(tokenA == address(token), "INVALID_TOKEN");
		return token.totalSupply();
	}

	function getTags() external view override returns (string[] memory) {
		string[] memory tags = new string[](4);
		tags[0] = "onchain";
		tags[1] = "supply";
		tags[2] = IERC20(address(token)).name();
		return tags;
	}

	function getDataTimestamp() external view override returns (uint256) {
		return block.timestamp;
	}

	function getAssetID() external view returns (string memory) {
		return IERC20(token).name();
	}
}
