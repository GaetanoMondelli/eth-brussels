// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { PoolKey } from "./Uniswap/V4-Core/types/PoolId.sol";
import { IPoolManager } from "./Uniswap/V4-Core/interfaces/IPoolManager.sol";
import { Oracle } from "./Oracle.sol";
import { PoolId, PoolIdLibrary } from "./Uniswap/V4-Core/types/PoolId.sol";
import { BaseHook } from "./Hooks/BaseHook.sol";
import { Hooks } from "./Uniswap/V4-Core/libraries/Hooks.sol";
import { TickMath } from "./Uniswap/V4-Core/libraries/TickMath.sol";

contract FixedLiquidityPriceOracle is BaseHook {
	using Oracle for Oracle.Observation[65535];
	using PoolIdLibrary for PoolKey;

	error OnlyPoolManager();

	modifier onlyByManager() {
		if (msg.sender != address(poolManager)) revert();
		_;
	}

	error OnlyOneOraclePoolAllowed();
	error OraclePositionsMustBeFullRange();
	error OraclePoolMustLockLiquidity();

	struct ObservationState {
		uint16 index;
		uint16 cardinality;
		uint16 cardinalityNext;
	}

	mapping(PoolId => Oracle.Observation[65535]) public observations;
	mapping(PoolId => ObservationState) public states;

	function getObservation(
		PoolKey calldata key,
		uint256 index
	) external view returns (Oracle.Observation memory observation) {
		observation = observations[PoolId.wrap(keccak256(abi.encode(key)))][
			index
		];
	}

	function getState(
		PoolKey calldata key
	) external view returns (ObservationState memory state) {
		state = states[PoolId.wrap(keccak256(abi.encode(key)))];
	}

	function _blockTimestamp() internal view virtual returns (uint32) {
		return uint32(block.timestamp);
	}

	constructor(IPoolManager _manager) BaseHook(_manager) {}

	function getHooksCalls() public pure override returns (Hooks.Calls memory) {
		return
			Hooks.Calls({
				beforeInitialize: true,
				afterInitialize: true,
				beforeModifyPosition: true,
				afterModifyPosition: true,
				beforeSwap: true,
				afterSwap: false,
				beforeDonate: false,
				afterDonate: false
			});
	}

	function beforeInitialize(
		address,
		PoolKey calldata key,
		uint160,
		bytes calldata
	) external view override onlyByManager returns (bytes4) {
		// This is to limit the fragmentation of pools using this oracle hook. In other words,
		// there may only be one pool per pair of tokens that use this hook. The tick spacing is set to the maximum
		// because we only allow max range liquidity in this pool.
		if (key.fee != 0 || key.tickSpacing != poolManager.MAX_TICK_SPACING())
			revert OnlyOneOraclePoolAllowed();
		return FixedLiquidityPriceOracle.beforeInitialize.selector;
	}

	function afterInitialize(
		address,
		PoolKey calldata key,
		uint160,
		int24,
		bytes calldata
	) external override onlyByManager returns (bytes4) {
		PoolId id = key.toId();
		(states[id].cardinality, states[id].cardinalityNext) = observations[id]
			.initialize(_blockTimestamp());
		return FixedLiquidityPriceOracle.afterInitialize.selector;
	}

	function getObservationLiquidity(
		PoolKey calldata key,
		uint32 secondsAgo
	) external view returns (uint160 liquidity) {
		PoolId id = key.toId();
		ObservationState memory state = states[id];
		(, int24 tick, , ) = poolManager.getSlot0(id);
		uint128 liquidity = poolManager.getLiquidity(id);
		return liquidity;
	}

	function _updatePool(PoolKey calldata key) private {
		PoolId id = key.toId();
		(, int24 tick, , ) = poolManager.getSlot0(id);

		uint128 liquidity = poolManager.getLiquidity(id);

		(states[id].index, states[id].cardinality) = observations[id].write(
			states[id].index,
			_blockTimestamp(),
			0,
			liquidity,
			states[id].cardinality,
			states[id].cardinalityNext
		);
	}

	function beforeModifyPosition(
		address,
		PoolKey calldata key,
		IPoolManager.ModifyPositionParams calldata params,
		bytes calldata
	) external override onlyByManager returns (bytes4) {
		int24 maxTickSpacing = poolManager.MAX_TICK_SPACING();
		if (
			params.tickLower != TickMath.minUsableTick(maxTickSpacing) ||
			params.tickUpper != TickMath.maxUsableTick(maxTickSpacing)
		) revert OraclePositionsMustBeFullRange();
		_updatePool(key);
		return FixedLiquidityPriceOracle.beforeModifyPosition.selector;
	}

	function beforeSwap(
		address,
		PoolKey calldata key,
		IPoolManager.SwapParams calldata,
		bytes calldata
	)
		external
		override
		onlyByManager
		returns (
			// returns (bytes4, BeforeSwapDelta, uint24)
			bytes4
		)
	{
		_updatePool(key);
		return this.beforeSwap.selector;
	}

	function observe(
		PoolKey calldata key,
		uint32[] calldata secondsAgos
	)
		external
		view
		returns (
			int56[] memory tickCumulatives,
			uint160[] memory secondsPerLiquidityCumulativeX128s
		)
	{
		PoolId id = key.toId();

		ObservationState memory state = states[id];

		(, int24 tick, , ) = poolManager.getSlot0(id);

		uint128 liquidity = poolManager.getLiquidity(id);

		return
			observations[id].observe(
				_blockTimestamp(),
				secondsAgos,
				tick,
				state.index,
				liquidity,
				state.cardinality
			);
	}

	function increaseCardinalityNext(
		PoolKey calldata key,
		uint16 cardinalityNext
	) external returns (uint16 cardinalityNextOld, uint16 cardinalityNextNew) {
		PoolId id = PoolId.wrap(keccak256(abi.encode(key)));

		ObservationState storage state = states[id];

		cardinalityNextOld = state.cardinalityNext;
		cardinalityNextNew = observations[id].grow(
			cardinalityNextOld,
			cardinalityNext
		);
		state.cardinalityNext = cardinalityNextNew;
	}
}
