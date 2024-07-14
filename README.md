# ETH BRUSSELS

## What it does

### Oracle data and on-chain Aggregator

By aggregating prices over a certain period using secure and reliable price oracles, and connecting this data to the supply of the tokens via a smart contract, we use similar methodologies to rank assets in indexes.

![formula1](/formula.png)

[DataAggreagtor.sol Contract](/packages/hardhat/contracts/DataAggreagtor.sol#L224)

We use the `updateTokenParams` to collect feeds.

```JAVA
function updateTokenParams(
		uint256[] memory _totalSupplies,
		uint256[] memory _liquidities
	) external {
		for (uint256 i = 0; i < dataProviders.length; i++) {
			DataTypes dataType = dataProviders[i].getDataType();
			if (dataType == DataTypes.PRICE) {
				if (isOnSameChain(dataProviders[i].getChainId())) {
					prices[tokens[dataProviders[i].getLabel()]] = dataProviders[
						i
					].getMetricData();
				}
			}
			if (dataType == DataTypes.TOTAL_SUPPLY) {
				if (isOnSameChain(dataProviders[i].getChainId())) {
					totalSupplies[
						tokens[dataProviders[i].getLabel()]
					] = dataProviders[i].getMetricData();
				}
			}
			if (dataType == DataTypes.LIQUIDITY) {
				if (isOnSameChain(dataProviders[i].getChainId())) {
					liquidities[
						tokens[dataProviders[i].getLabel()]
					] = dataProviders[i].getMetricData();
				}
			}

			tokenParamsTimestampUpdates[
				tokens[dataProviders[i].getLabel()]
			] = dataProviders[i].getDataTimestamp();
		}

		// DATA MESSAGES
		if (isMainChain()) {
			// RECEIVED
			for (uint256 i = 0; i < messages.length; i++) {
				if (messages[i].dataType == DataTypes.PRICE) {
					prices[tokens[messages[i].label]] = messages[i].metricData;
				}
				if (messages[i].dataType == DataTypes.TOTAL_SUPPLY) {
					totalSupplies[tokens[messages[i].label]] = messages[i]
						.metricData;
				}
				if (messages[i].dataType == DataTypes.LIQUIDITY) {
					liquidities[tokens[messages[i].label]] = messages[i]
						.metricData;
				}
				tokenParamsTimestampUpdates.push(messages[i].dataTimestamp);
			}
		}

		if (!isMainChain()) {
			// SEND
			Data[] memory _supplyMessages = new Data[](tokenInfo.length);
			Data[] memory _liquidityMessages = new Data[](tokenInfo.length);

			Data[] memory _priceMessages = new Data[](tokenInfo.length);

			for (uint256 i = 0; i < tokenInfo.length; i++) {
				if (chainId == tokenInfo[i]._chainId) {
					_supplyMessages[i] = Data(
						tokenInfo[i]._name,
						tokenInfo[i]._address,
						_totalSupplies[i],
						block.timestamp,
						DataTypes.TOTAL_SUPPLY,
						chainId
					);
					_liquidityMessages[i] = Data(
						tokenInfo[i]._name,
						tokenInfo[i]._address,
						_liquidities[i],
						block.timestamp,
						DataTypes.LIQUIDITY,
						chainId
					);
					_priceMessages[i] = Data(
						tokenInfo[i]._name,
						tokenInfo[i]._address,
						prices[i],
						block.timestamp,
						DataTypes.PRICE,
						chainId
					);
				}
			}
		}
  }
```

#### Multi-chain data aggregation

Some of this data is available on different chains, so we implemented a messaging system with layerzero to inform a primary chain (mainchain) of secondary chain data. Every time we need to create an index based on market cap we need to make sure supply data are updated.

Note that for simplicity we are aware that we should aggregate also supply data within prices however it would be complicated to ensure supply data are in sync with price ones on different chains and for this reason we decided to get supply (and all chain data) only when we want to persist an index. So instead of having avg( ith-price*ith-supply)) we have avg(ith-prices) * last supply. In case of high standard deviation (or variance), this could lead to problems.

[IndexAggreagtor.sol Contract](xtf/packages/hardhat/contracts/IndexAggreagtor.sol#L224)

When the main aggreagtor chain receives data they store them in a message inbox variable to be processed later for gas reasons.

```Java
	function _lzReceive(
		Origin calldata /*_origin*/,
		bytes32 /*_guid*/,
		bytes calldata payload,
		address /*_executor*/,
		bytes calldata /*_extraData*/
	) internal override {
		// data = abi.decode(payload, (string));
		Data[] memory _inboxMessages = abi.decode(payload, (Data[]));
		for (uint256 i = 0; i < _inboxMessages.length; i++) {
			messages.push(_inboxMessages[i]);
		}
	}
```
--

![formula3](/formula.png)

#### Bribing system

We implemented a bribing system where the index aggregator has funds to pay oracle fees or to incitives user to user to pull updated data within the required timeframe.
Users can see the remaining funds and determine if there is enough runway to maintain a safe index.

---

### Uniswap Foundation

The Multi-Chain Data Aggregator initially collected data about token liquidity using Uniswap V3 pools. Unfortunately we realise that pool managers can manipulate liquidity by adding or removing it, affecting observed values. A better solution uses Uniswap V4 hooks, which prevent changes to the initial liquidity by reverting any attempts to add or remove liquidity. This approach ensures accurate data by creating new observation states (via Uniswap Oracle) whenever a swap occurs.

- [UniswapV3 Liquidity Feed Provider ](/packages/hardhat/contracts/UniswapV3LiquidityProvider.sol.sol)
- [UniswapV3 Price Feed Provider](/packages/hardhat/contracts/UniswapV3PriceProvider.sol)
- [UniswapV4 Liquidity Feed Provider ](/packages/hardhat/contracts/UniswapV4LiquidityProvider.sol)
- [UniswapV4 Price Feed Provider](/packages/hardhat/contracts/UniswapV4PriceProvider.sol)

#### v4 Hook 
- [v4 Hook to prevent manager to manipulate liquidity](packages/hardhat/contracts/FixedLiquidityPriceOracle.sol)

Note: we used a not updated implementation of hooks from `awesome uniswap hooks` [here](https://github.com/ora-io/awesome-uniswap-hooks) compatible with Hardhat [here](https://github.com/Gnome101/UniswapV4Hardhat)

``` java

  // REVERTING when trying to modify liquidity
	function beforeModifyPosition(  // now beforeAddingLiquidity & beforeRemovingLiquidity
		address,
		PoolKey calldata key,
		IPoolManager.ModifyPositionParams calldata params,
		bytes calldata
	) external override onlyByManager returns (bytes4) {
		revert LiquidityCannoBeChanged();
	}


  // Pushing an observation about the pool state to the data aggregator (same as v3 Oracles)
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

  	Hooks.Calls({  // --> now Hooks.Permissions
				beforeInitialize: true,
				afterInitialize: true,
				beforeModifyPosition: true,
				afterModifyPosition: false,
				beforeSwap: true,
				afterSwap: false,
				beforeDonate: false,
				afterDonate: false
			});

```


### Flare Network

We decided to deploy the Data Aggregator on Conston2 to take advantage of the cost-effective price oracles (FTSOv2) and integrate it with data from other chains that require fewer updates using a LayerZero OmniApp.


Contracts:

- [FTSOV2 Data Provider](/packages/hardhat/contracts/FtsoV2FeedConsumer.sol)
- [Data Aggregator using layerZero](/packages/hardhat/contracts/DataAggregator.sol)
- [Data Provider Interface](/packages/hardhat/contracts/IDataProvider.sol)

Training contracts:

- [FTSOV2 Data Provider](/packages/hardhat/contracts/FTSOv2Provider.sol)
- [FtsoV2FeedConsumerLz](/packages/hardhat/contracts/FtsoV2FeedConsumerLz.sol)
- [FtsoV2FeedConsumer](/packages/hardhat/contracts/FtsoV2FeedConsumer.sol)

### Pyth Network

We integrated an example of Pyth Network feed as a data provider due to its vast variety of price feeds and coverage of the biggest pairs. This extensive range of data can be used for many use cases and integrates seamlessly with other on-chain data to create comprehensive metrics for DeFi protocols.


- [PythReader Price Provider Example](/packages/hardhat/contracts/PythReader.sol)
- [Data Provider Interface](/packages/hardhat/contracts/IDataProvider.sol)

### Chronicle Protocol

We decided to add Chronicle as a data provider to take advantage of the assets it covers and to propagate and integrate price feeds with other on-chain data, creating metrics that can be utilized by other protocols. xx11 was chosen because it is one of the first protocols to provide price feeds and is known for its reliability.

- [Chronicle Price Provider Example](/packages/hardhat/contracts/ChronicleDataProvider.sol)
- [Data Provider Interface](/packages/hardhat/contracts/IDataProvider.sol)

### LayerZero

Our main idea is to create a data aggregator dapp acting as a source of truth that is accessible on different chains. We believe that multi-chain functionality is not just about bridging tokens; it’s about expanding the reach of certain data across various networks. 

By making data available on different networks, protocols can perform more effectively. This is why we chose the Omni App (OApp) to make relevant on-chain data available on all networks.


- [Omni app DataAggregator using layerZero](/packages/hardhat/contracts/DataAggregator.sol)

Training contracts:

- [FtsoV2FeedConsumerLz](/packages/hardhat/contracts/FtsoV2FeedConsumerLz.sol)
- [Simple string update example](packages/hardhat/contracts/lz.sol)
