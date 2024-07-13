// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { DataAggregator, TokenInfo, AggregatorParams } from "./DataAggregator.sol";

contract IndexGenerator is DataAggregator {
	uint256 public indexSize;

	constructor(
		TokenInfo[] memory _tokenInfo,
		address _endpoint,
		address[] memory _dataProviders,
		AggregatorParams memory _aggregatorParams,
		uint256 indexSize
	) DataAggregator(_tokenInfo, _endpoint, _dataProviders, _aggregatorParams) {
		indexSize = indexSize;
	}

	function persistIndex(
		uint256[] memory indexOrders,
		string memory tag
	) public returns (bool) {
		require(
			indexOrders.length == indexSize,
			"IndexAggregator: Invalid length of indexOrders"
		);

		// indexOrders is an array index order [2,0,1] means 2nd token, 0th token, 1st token for price calculation

		// if (
		// 	keccak256(abi.encodePacked(tag)) != keccak256(abi.encodePacked(""))
		// ) {
		// 	for (uint256 i = 0; i < tmpTokens.length; i++) {
		// 		delete tmpTokens[i];
		// 	}
		// 	for (uint256 i = 0; i < tokenInfo.length; i++) {
		// 		for (uint256 j = 0; j < tokenInfo[i]._tags.length; j++) {
		// 			if (
		// 				keccak256(abi.encodePacked(tokenInfo[i]._tags[j])) ==
		// 				keccak256(abi.encodePacked(tag))
		// 			) {
		// 				// need to check if the tag was verified on the tagging system
		// 				// require(
		// 				//     taggingVerifier.tokenSymbolToVerifiedTagsMap(tokenInfo[i]._symbol, tag) == true,
		// 				//     "IndexAggregator: Tag not verified"
		// 				// );
		// 				tmpTokens.push(tokenInfo[i]);
		// 			}
		// 		}
		// 	}
		// 	require(
		// 		tmpTokens.length == indexOrders.length,
		// 		"IndexAggregator: Invalid length of token with required tags"
		// 	);
		// } else {
		// 	require(
		// 		indexOrders.length == tokenInfo.length,
		// 		"IndexAggregator: Invalid length of indexOrders"
		// 	);
		// }

		uint256 token_a_value;
		uint256 token_b_value;
		for (uint256 i = 0; i < indexOrders.length - 1; i++) {
			token_a_value = 0;
			token_b_value = 0;

			for (uint256 j = 0; j < movingAverage[indexOrders[i]].length; j++) {
				token_a_value +=
					movingAverage[indexOrders[i]][j] *
					totalSupplies[indexOrders[i]];
				token_b_value +=
					movingAverage[indexOrders[i + 1]][j] *
					totalSupplies[indexOrders[i + 1]];
			}

			require(token_a_value > 0, "IndexAggregator: Token value is zero");
			require(token_b_value > 0, "IndexAggregator: Token value is zero");
			require(
				token_a_value > token_b_value,
				"IndexAggregator: order is not correct"
			);
		}

		lastIndexOrder = indexOrders;
		lastIndexTimestamp = block.timestamp;
		return true;
	}
}
