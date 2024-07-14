// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { DataAggregator, TokenInfo, AggregatorParams } from "./DataAggregator.sol";

contract IndexGeneratorV2 {
	uint256 public indexSize;
	uint256 public counter = 0;

	constructor() {}

	function colleectBribes() public returns (bool) {
		counter++;
		return true;
	}

	function updateTokenParams(
		TokenInfo[] memory _tokenInfo,
		address _endpoint,
		address[] memory _dataProviders,
		AggregatorParams memory _aggregatorParams,
		uint256 indexSize
	) public returns (bool) {
		counter++;
		return true;
	}

	function updateTokenPars() public returns (bool) {
		counter++;
		return true;
	}

	function sendMainChain() public returns (bool) {
		counter++;
		return true;
	}

	function persistIndex(
		uint256[] memory indexOrders,
		string memory tag
	) public returns (bool) {
		counter++;

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

		return true;
	}
}
