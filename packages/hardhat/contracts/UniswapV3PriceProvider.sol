// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./IDataProvider.sol";
import { IERC20 } from "./IERC20.sol";

contract UniswapV3PriceProvider is IDataProvider {
	IUniswapV3Factory public factory;
	uint24[] public feeTiers = [500, 3000, 10000]; // Example fee tiers: 0.05%, 0.3%, 1% these are Uniswap V3 standards
	address[] public comparisonTokens;
	uint256 public mockPrice = 1000;
	address public token;
	uint32 public chainId;

	constructor(
		address _factory,
		address[] memory _comparisonTokens,
		address _token,
		uint32 _chainId
	) {
		factory = IUniswapV3Factory(_factory);
		comparisonTokens = _comparisonTokens;
		token = _token;
		chainId = _chainId;
	}

	function getPoolsForToken(
		address token
	) public view returns (address[] memory) {
		uint256 poolCount = 0;
		address[] memory tempPools = new address[](
			comparisonTokens.length * feeTiers.length
		);

		for (uint256 i = 0; i < comparisonTokens.length; i++) {
			if (comparisonTokens[i] == token) continue;
			for (uint256 j = 0; j < feeTiers.length; j++) {
				address pool = factory.getPool(
					token,
					comparisonTokens[i],
					feeTiers[j]
				);
				if (pool != address(0)) {
					tempPools[poolCount] = pool;
					poolCount++;
				}
			}
		}

		// Create an array of the actual size
		address[] memory pools = new address[](poolCount);
		for (uint256 i = 0; i < poolCount; i++) {
			pools[i] = tempPools[i];
		}

		return pools;
	}

	function getPrice(
		address token
	) public view returns (uint256 averagePrice) {
		uint256 sumPrice = 0;
		uint256 count = 0;
		address[] memory pools = getPoolsForToken(token);

		for (uint256 i = 0; i < pools.length; i++) {
			sumPrice += mockPrice;
			count++;
		}

		if (count > 0) {
			averagePrice = sumPrice / count;
		}
	}

	function getLabel() external view override returns (string memory) {
		return
			string(
				abi.encodePacked("UniswapV3PriceProvider", IERC20(token).name())
			);
	}

	function getMetricData(
	) external view override returns (uint256) {
		return getPrice(token);
	}

	function getDataTimestamp() external view override returns (uint256) {
		return block.timestamp;
	}

	function getTags() external view override returns (string[] memory) {
		string[] memory tags = new string[](4);
		tags[0] = "onchain";
		tags[1] = "uniswap";
		tags[2] = "price";
		tags[3] = IERC20(token).name();
		return tags;
	}

	function getDataType() external pure returns (DataTypes) {
		return DataTypes.PRICE;
	}

	function getAssetAddress() external view override returns (address) {
		return token;
	}

	function getChainId() external view override returns (uint32) {
		return chainId;
	}
}
