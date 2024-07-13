// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IChronicle.sol";
import "./IDataProvider.sol";
import { IERC20 } from "./IERC20.sol";
import { IFlareContractRegistry } from "@flarenetwork/flare-periphery-contracts/coston2/util-contracts/userInterfaces/IFlareContractRegistry.sol";
import { IFastUpdater } from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFastUpdater.sol";

contract FTSOv2DataProvider is IDataProvider {
	/// @notice The token to read data for.
	address public token;
	IFlareContractRegistry internal contractRegistry;
	IFastUpdater internal ftsoV2;
	uint256[] public feedIndexes;

	constructor(address _token, uint256[] memory _feedIndex) {
		// Flare FTSOv2 configuration
		contractRegistry = IFlareContractRegistry(
			0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019
		);
		ftsoV2 = IFastUpdater(
			contractRegistry.getContractAddressByName("FastUpdater")
		);
		token = _token;
		feedIndexes = _feedIndex;
	}

	function getFtsoV2CurrentFeedValues()
		public
		view
		returns (
			uint256[] memory _feedValues,
			int8[] memory _decimals,
			uint64 _timestamp
		)
	{
		(
			uint256[] memory feedValues,
			int8[] memory decimals,
			uint64 timestamp
		) = ftsoV2.fetchCurrentFeeds(feedIndexes);
		/* Your custom feed consumption logic. In this example the values are just returned. */
		return (feedValues, decimals, timestamp);
	}

	function getLabel() external view override returns (string memory) {
		return string(abi.encodePacked("priceFTSOv2", IERC20(token).name()));
	}

	function getMetricData(
		address tokenA
	) external view override returns (uint256) {
		require(tokenA == token, "Invalid token address");
		(uint256[] memory feedValues, , ) = getFtsoV2CurrentFeedValues();
		return feedValues[0];
	}

	function getDataTimestamp() external view override returns (uint256) {
		(, , uint64 timestamp) = ftsoV2.fetchCurrentFeeds(feedIndexes);
		return timestamp;
	}

	function getTags() external view override returns (string[] memory) {
		string[] memory tags = new string[](4);
		tags[0] = "partner";
		tags[1] = "chronicle";
		tags[2] = "price";
		tags[3] = IERC20(token).name();
	}

	function getAssetID() external view returns (string memory) {
		return IERC20(token).name();
	}
}
