// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IDataProvider.sol";
import { IERC20 } from "./IERC20.sol";

contract TotalSupplyProvider is IDataProvider {
	address public token;
	uint32 public chainId;

	constructor(address _token, uint32 _chainId) {
		token = _token;
		chainId = _chainId;
	}

	function getLabel() external view override returns (string memory) {
		return
			string(
				abi.encodePacked("totalSupply", IERC20(address(token)).name())
			);
	}

	function getMetricData() external view override returns (uint256) {
		return IERC20(token).totalSupply();
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

	function getDataType() external pure returns (DataTypes) {
		return DataTypes.TOTAL_SUPPLY;
	}

	function getAssetAddress() external view override returns (address) {
		return token;
	}

	function getChainId() external view override returns (uint32) {
		return chainId;
	}
}
