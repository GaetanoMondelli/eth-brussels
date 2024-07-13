// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IDataProvider {
	function getLabel() external view returns (string memory);

	function getMetricData() external view returns (uint256);

	function getTags() external view returns (string[] memory);

	function getDataTimestamp() external view returns (uint256);

	function getDataType() external view returns (DataTypes);

	function getAssetAddress() external view returns (address);

	function getChainId() external view returns (uint32);
}

enum DataTypes {
	PRICE,
	LIQUIDITY,
	TOTAL_SUPPLY,
	CATEGORY,
	OTHER
}

struct Data {
	string label;
	address assetAddress;
	uint256 metricData;
	uint256 dataTimestamp;
	DataTypes dataType;
	uint32 chainId;

}
