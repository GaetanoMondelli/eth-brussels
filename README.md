# ETH BRUSSELS

## What it does



### Oracle data and on-chain Aggregator

By aggregating prices over a certain period using secure and reliable price oracles, and connecting this data to the supply of the tokens via a smart contract, we use similar methodologies to rank assets in indexes.


![formula1](/formula.png)

[IndexAggreagtor.sol Contract](xtf/packages/hardhat/contracts/IndexAggreagtor.sol#L224)

We use the `collectPriceFeeds` to collect prices (using Chanilnk AggregatorV3Interface we mocked here [MockPriceAggregator](xtf/packages/hardhat/contracts/MockAggregator.sol))

```JAVA

    function collectPriceFeeds() external {
        require(block.timestamp - lastSampleTime >= samplingFrequency, "IndexAggregator: Sampling frequency not reached");

        if (block.timestamp - lastSampleTime >= timeWindow) {
            for (uint256 i = 0; i < tokenInfo.length; i++) {
                if (movingAverage[i].length > 0) {
                    movingAverage[i].pop();
                }
            }
        }

        for (uint256 i = 0; i < tokenInfo.length; i++) {
            (, int256 answer, , , ) = AggregatorV3Interface(tokenInfo[i]._aggregator).latestRoundData();

            movingAverage[i].push(uint256(answer));
            uint256 sum = 0;
            if (movingAverage[i].length > sampleSize) {
                movingAverage[i].pop();
            }
            for (uint256 j = 0; j < movingAverage[i].length; j++) {
                sum += movingAverage[i][j];
            }
        }
        lastSampleTime = block.timestamp;
        // if there is enough bribe pay it to the caller
        if (bribeUnit > 0) {
            payable(msg.sender).transfer(bribeUnit);
        }
    }
 ```

#### Multi-chain data aggregation 

Some of this data is available on different chains, so we implemented a messaging system to inform a primary chain (mainchain) of secondary chain data. Every time we need to create an index based on market cap we need to make sure supply data are updated.

Note that for simplicity we are aware that we should aggregate also supply data within prices however it would be complicated to ensure supply data are in sync with price ones on different chains and for this reason we decided to get supply (and all chain data) only when we want to persist an index. So instead of having avg( ith-price*ith-supply))  we have avg(ith-prices) * last supply. In case of high standard deviation (or variance), this could lead to problems. 

![formuala2](/formula2.png)

[IndexAggreagtor.sol Contract](xtf/packages/hardhat/contracts/IndexAggreagtor.sol#L224)

We use the `collectPriceFeeds` to collect prices (using Chanilnk AggregatorV3Interface we mocked here [MockPriceAggregator](xtf/packages/hardhat/contracts/MockAggregator.sol))

```Java
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal virtual override {

        IndexUpdateMessage memory indexMessage = abi.decode(
            message.data,
            (IndexUpdateMessage)
        );
        for (uint256 i = 0; i < indexMessage.liquidityMessages.length; i++) {
            LiquidityMessage memory liquidityMessage = indexMessage.liquidityMessages[i];
            liquidityMessages.push(liquidityMessage);
        }
        for (uint256 i = 0; i < indexMessage.supplyMessages.length; i++) {
            SupplyMessage memory supplyMessage = indexMessage.supplyMessages[i];
            supplyMessages.push(supplyMessage);
        }
    }
```

Note that we are not processing messages here as it could be too expensive and this could lead to failure.



We use the `updateTokenParams` to replay and process all the receveid messages on mainchain to update it with all the external (sidechain) (see the `isMainChain()` check).
The same method on `sidechain` is used to populate the outbox of messages that will be send to the `mainchain` using the `send` method ([IndexAggreagtor.sol Send](xtf/packages/hardhat/contracts/IndexAggreagtor.sol#332))

--

[IndexAggreagtor.sol updateTokenParams](xtf/packages/hardhat/contracts/IndexAggreagtor.sol#150)

```Java
    function updateTokenParams(uint256[] memory _totalSupplies, uint256[] memory _liquidities) external {

        for (uint256 i = 0; i < tokenInfo.length; i++) {
            if (tokenInfo[i]._chainId == chainId) {
                liquidities[i] = liquidityManager.getTotalLiquidityForToken(tokenInfo[i]._address);
                totalSupplies[i] = IERC20(tokenInfo[i]._address).totalSupply();
                tokenParamsTimestampUpdates[i] = block.timestamp;
            }
        }

        if(isMainChain()){
            for (uint256 i = 0; i < totalSupplies.length; i++) {
                for (uint256 j = 0; j < tokenInfo.length; j++) {
                    if (tokenInfo[j]._address == supplyMessages[i].token) {
                        totalSupplies[j] = supplyMessages[i].supply;
                        tokenParamsTimestampUpdates[j] = liquidityMessages[i].timestamp;
                    }
                    continue;
                }
            }

            for (uint256 i = 0; i < liquidities.length; i++) {
                for (uint256 j = 0; j < tokenInfo.length; j++) {
                    if (tokenInfo[j]._address == liquidityMessages[i].token) {
                        liquidities[j] = liquidityMessages[i].liquidity;
                        tokenParamsTimestampUpdates[j] = liquidityMessages[i].timestamp;
                    }
                    continue;
                }
            }
        }

        if(!isMainChain()){
            SupplyMessage[] memory _supplyMessages = new SupplyMessage[](tokenInfo.length);
            LiquidityMessage[] memory _liquidityMessages = new LiquidityMessage[](tokenInfo.length);
            for (uint256 i = 0; i < tokenInfo.length; i++) {
                if(chainId == tokenInfo[i]._chainId){
                    _supplyMessages[i] = SupplyMessage(tokenInfo[i]._address, _totalSupplies[i], chainId, block.timestamp);
                    _liquidityMessages[i] = LiquidityMessage(tokenInfo[i]._address, _liquidities[i], chainId, block.timestamp);
                }
            }
        }
    }
```




#### Other on-chain data and Liquidity 

We noted that other on-chain data can be used to enhance the index definition. For example, we could combine liquidity data from DEXes (like Uniswap, Compound, and 1inch) to decide which assets to include or exclude, filtering out assets with insufficient liquidity that would make it difficult to mint an XTF fund vault.
For this demo, we deployed a mock implementation of [UniswapV3](xtf/packages/hardhat/contracts/IUniswapV3Factory.sol) where liquidity is defined by how many times we could perform an exchange with a certain token. We pulled data from all Uniswap pools that included the token we were evaluating and some common reference tokens, such as USDC, USDT, and ETH. This approach gave us a metric telling us how easily we could swap common reference tokens for our selected token. 
We implemented a dedicated smart contract ([Liquidity Manager](xtf/packages/hardhat/contracts/LiquidityManager.sol)) to gather this information from all pools and make the liquidity metric available to our index aggregator. This allows us to filter out tokens with insufficient liquidity if necessary.

Contracts:
- [UniswapV3 Factory](xtf/packages/hardhat/contracts/IUniswapV3Factory.sol)
- [Mock UniswapV3 Entry Point](xtf/packages/hardhat/contracts/MockUniswapV3Factory.sol)
- [Mock UniswapV3 Pool](xtf/packages/hardhat/contracts/MockUniswapV3Pool.sol)
- [UniswapV3 Pool Deployer](xtf/packages/hardhat/contracts/IUniswapV3PoolDeployer.sol)





![formula3](/formula3.png)

#### Bribing system

We implemented a bribing system where the index aggregator has funds and pays a certain amount to the first user who invokes the pull method within the required timeframe. 
Users can see the remaining funds and determine if there is enough runway to maintain a safe index.

![upkeep](/upkeep.png)


----

### Uniswap Foundation 

The Multi-Chain Data Aggregator collects data about token liquidity using Uniswap V3 pools, highlighting vulnerabilities where pool managers can manipulate liquidity by adding or removing it, thus affecting observed values. A better solution is presented using Uniswap V4 hooks, which fix the initial liquidity by reverting any attempts to add or remove liquidity. This approach ensures accurate data by collecting new observation states (via Uniswap Oracle) whenever a swap occurs.


### Flare Network

code references

### Pyth Network

code references

###  Chronicle Protocol 

code references

### LayerZero

code references