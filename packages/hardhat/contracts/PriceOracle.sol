// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { PoolKey } from "./Uniswap/V4-Core/types/PoolId.sol";
import { IPoolManager } from "./Uniswap/V4-Core/interfaces/IPoolManager.sol";
import { Oracle } from "./Oracle.sol";
import { PoolId, PoolIdLibrary } from "./Uniswap/V4-Core/types/PoolId.sol";
import { BaseHook } from "./Hooks/BaseHook.sol";
import { Hooks } from "./Uniswap/V4-Core/libraries/Hooks.sol";
import { TickMath } from "./Uniswap/V4-Core/libraries/TickMath.sol";

contract PriceOracle is BaseHook {
	using Oracle for Oracle.Observation[65535];
	using PoolIdLibrary for PoolKey;

	error OnlyPoolManager();

	modifier onlyByManager() {
		if (msg.sender != address(poolManager)) revert();
		_;
	}

	/// @notice Oracle pools do not have fees because they exist to serve as an oracle for a pair of tokens
	error OnlyOneOraclePoolAllowed();

	/// @notice Oracle positions must be full range
	error OraclePositionsMustBeFullRange();

	/// @notice Oracle pools must have liquidity locked so that they cannot become more susceptible to price manipulation
	error OraclePoolMustLockLiquidity();

	struct ObservationState {
		uint16 index;
		uint16 cardinality;
		uint16 cardinalityNext;
	}

	/// @notice The list of observations for a given pool ID
	mapping(PoolId => Oracle.Observation[65535]) public observations;
	/// @notice The current observation array state for the given pool ID
	mapping(PoolId => ObservationState) public states;

	/// @notice Returns the observation for the given pool key and observation index
	function getObservation(
		PoolKey calldata key,
		uint256 index
	) external view returns (Oracle.Observation memory observation) {
		observation = observations[PoolId.wrap(keccak256(abi.encode(key)))][
			index
		];
	}

	/// @notice Returns the state for the given pool key
	function getState(
		PoolKey calldata key
	) external view returns (ObservationState memory state) {
		state = states[PoolId.wrap(keccak256(abi.encode(key)))];
	}

	/// @dev For mocking
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
		return PriceOracle.beforeInitialize.selector;
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
		return PriceOracle.afterInitialize.selector;
	}

	/// @dev Called before any action that potentially modifies pool price or liquidity, such as swap or modify position
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
		return PriceOracle.beforeModifyPosition.selector;
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
		// return (
		// 	PriceOracle.beforeSwap.selector,
		// 	BeforeSwapDeltaLibrary.ZERO_DELTA,
		// 	0
		// );
		return this.beforeSwap.selector;
	}

	/// @notice Observe the given pool for the timestamps
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

	/// @notice Increase the cardinality target for the given pool
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
