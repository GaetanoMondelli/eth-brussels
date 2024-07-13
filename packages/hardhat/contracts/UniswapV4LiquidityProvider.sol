// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import { FixedLiquidityPriceOracle, Oracle } from "./FixedLiquidityPriceOracle.sol";
import "./ILiquidityProvider.sol";
import { PoolId, PoolKey } from "./Uniswap/V4-Core/types/PoolId.sol";
import { TickMath } from "./Uniswap/V4-Core/libraries/TickMath.sol";
import "./IDataProvider.sol";
import { IERC20 } from "./IERC20.sol";

contract UniswapV4LiquidityProvider is ILiquidityProvider, IDataProvider {
	FixedLiquidityPriceOracle public v4HookPriceOracle;
	PoolKey[] public poolKeysForSameAsset;
	address token;

	constructor(
		address _v4HookPriceOracle,
		PoolKey[] memory _poolKeysForSameAsset,
		address _token
	) {
		v4HookPriceOracle = FixedLiquidityPriceOracle(_v4HookPriceOracle);
		for (uint256 i = 0; i < _poolKeysForSameAsset.length; i++) {
			poolKeysForSameAsset.push(_poolKeysForSameAsset[i]);
		}
		token = _token; //same as currency0
	}

	function getTokenLiquidity(
		address _token
	) public view returns (uint256 totalLiquidity) {
		require(_token == token, "Invalid token address");
		uint256 sumLiquidity = 0;
		uint256 count = 0;

		for (uint256 i = 0; i < poolKeysForSameAsset.length; i++) {
			PoolKey memory key = poolKeysForSameAsset[i];
			sumLiquidity += v4HookPriceOracle.getObservationLiquidity(key, 0);
			count++;
		}

		if (count > 0) {
			totalLiquidity = sumLiquidity / count;
		}
	}

	function getPrice(
		address token
	) public view returns (uint256 averagePrice) {
		int256 sumTickCumulative = 0;
		uint256 count = 0;
		uint32 startTime;
		uint32 endTime;

		for (uint256 i = 0; i < poolKeysForSameAsset.length; i++) {
			PoolKey memory key = poolKeysForSameAsset[i];
			PoolId poolId = PoolId.wrap(keccak256(abi.encode(key)));
			FixedLiquidityPriceOracle.ObservationState
				memory state = v4HookPriceOracle.getState(key);

			if (state.cardinality > 1) {
				Oracle.Observation memory startObservation = v4HookPriceOracle
					.getObservation(key, 0);
				Oracle.Observation memory endObservation = v4HookPriceOracle
					.getObservation(key, state.cardinality - 1);

				startTime = startObservation.blockTimestamp;
				endTime = endObservation.blockTimestamp;

				sumTickCumulative +=
					int256(endObservation.tickCumulative) -
					int256(startObservation.tickCumulative);
				count += (endTime - startTime);
			}
		}

		if (count > 0) {
			int256 averageTick = sumTickCumulative / int256(count);
			averagePrice = tickToPrice(int24(averageTick));
		}
		return averagePrice;
	}

	function tickToPrice(int24 tick) internal pure returns (uint256 price) {
		return TickMath.getSqrtRatioAtTick(int24(tick));
	}

	function getLabel() external view override returns (string memory) {
		return
			string(
				abi.encodePacked(
					"UniswapV4LiquidityProvider",
					IERC20(token).name()
				)
			);
	}

	function getMetricData(
		address tokenA
	) external view override returns (uint256) {
		return getTokenLiquidity(tokenA);
	}

	function getTags() external view override returns (string[] memory) {
		string[] memory tags = new string[](4);
		tags[0] = "onchain";
		tags[1] = "uniswapv4";
		tags[2] = "liquidity";
		tags[3] = IERC20(token).name();
		return tags;
	}

	function getDataTimestamp() external view override returns (uint256) {
		return block.timestamp;
	}

	function getAssetID() external view returns (string memory) {
		return IERC20(token).name();
	}
}
