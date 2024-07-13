// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LiquidityManager } from "./LiquidityManager.sol";
import { MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { IFlareContractRegistry } from "@flarenetwork/flare-periphery-contracts/coston2/util-contracts/userInterfaces/IFlareContractRegistry.sol";
import { IFastUpdater } from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFastUpdater.sol";
import { IDataProvider } from "./IDataProvider.sol";

uint32 constant CALLBACK_GAS_LIMIT = 4_000_000;

struct TokenInfo {
	string _symbol;
	address _address;
	uint32 _chainId;
	address _aggregator;
	string[] _tags;
}

struct LiquidityMessage {
	address token;
	uint256 liquidity;
	uint32 chainId;
	uint256 timestamp;
}

struct SupplyMessage {
	address token;
	uint256 supply;
	uint32 chainId;
	uint256 timestamp;
}

struct AggregatorParams {
	uint256 _timeWindow;
	uint256 _sampleSize;
	uint256 _bribeUnit;
}

struct IndexUpdateMessage {
	LiquidityMessage[] liquidityMessages;
	SupplyMessage[] supplyMessages;
}

enum PayFeesIn {
	Native,
	LINK
}

error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);

contract DataAggregator is OApp {
	IDataProvider[] public dataProviders;
	TokenInfo[] public tokenInfo;
	TokenInfo[] tmpTokens;
	LiquidityManager public liquidityManager;
	mapping(string => uint256) public tokens;
	string[] public tokenSymbols;

	IFlareContractRegistry internal contractRegistry;
	IFastUpdater internal ftsoV2;

	LiquidityMessage[] public liquidityMessages;
	SupplyMessage[] public supplyMessages;

	uint256[] public totalSupplies;
	uint256[] public liquidities;
	uint256[] public tokenParamsTimestampUpdates;

	mapping(uint256 => uint256[]) public movingAverage;
	uint256 sampleSize;
	uint256 timeWindow;
	uint256 samplingFrequency;
	uint256 lastSampleTime;
	uint256[] public lastIndexOrder;
	mapping(string => uint256[]) public tagsIndexOrder;
	mapping(string => uint256) public tagsIndexTimestamp;
	uint256 public lastIndexTimestamp;
	uint256 public bribeUnit;
	uint32 public chainId;
	uint32 public mainChainId;
	uint256[] public feedIndexes = [0, 2, 9];

	constructor(
		TokenInfo[] memory _tokenInfo,
		address _liquidityManager,
		address _endpoint,
		AggregatorParams memory _aggregatorParams
	) OApp(_endpoint, msg.sender) {
		sampleSize = _aggregatorParams._sampleSize;
		timeWindow = _aggregatorParams._timeWindow;
		samplingFrequency = timeWindow / sampleSize;
		bribeUnit = _aggregatorParams._bribeUnit;
		liquidityManager = LiquidityManager(_liquidityManager);
		for (uint256 i = 0; i < _tokenInfo.length; i++) {
			tokenInfo.push(_tokenInfo[i]);
			tokenSymbols.push(_tokenInfo[i]._symbol);
			tokens[_tokenInfo[i]._symbol] = i;
			totalSupplies.push(IERC20(_tokenInfo[i]._address).totalSupply());
		}

		// Flare FTSOv2 configuration
		contractRegistry = IFlareContractRegistry(
			0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019
		);
		ftsoV2 = IFastUpdater(
			contractRegistry.getContractAddressByName("FastUpdater")
		);
	}

	function isMainChain() public view returns (bool) {
		return chainId == mainChainId;
	}

	// function setTaggingVerifier(address _taggingVerifier) external {
	// 	taggingVerifier = TaggingVerifier(_taggingVerifier);
	// }

	function setChainId(uint32 _chainId, uint32 _mainChainId) external {
		chainId = _chainId;
		mainChainId = _mainChainId;
	}

	function updateTokenParams(
		uint256[] memory _totalSupplies,
		uint256[] memory _liquidities
	) external {
		for (uint256 i = 0; i < tokenInfo.length; i++) {
			if (tokenInfo[i]._chainId == chainId) {
				liquidities[i] = liquidityManager.getTotalLiquidityForToken(
					tokenInfo[i]._address
				);
				totalSupplies[i] = IERC20(tokenInfo[i]._address).totalSupply();
				tokenParamsTimestampUpdates[i] = block.timestamp;
			}
		}

		if (isMainChain()) {
			for (uint256 i = 0; i < totalSupplies.length; i++) {
				for (uint256 j = 0; j < tokenInfo.length; j++) {
					if (tokenInfo[j]._address == supplyMessages[i].token) {
						totalSupplies[j] = supplyMessages[i].supply;
						tokenParamsTimestampUpdates[j] = liquidityMessages[i]
							.timestamp;
					}
					continue;
				}
			}

			for (uint256 i = 0; i < liquidities.length; i++) {
				for (uint256 j = 0; j < tokenInfo.length; j++) {
					if (tokenInfo[j]._address == liquidityMessages[i].token) {
						liquidities[j] = liquidityMessages[i].liquidity;
						tokenParamsTimestampUpdates[j] = liquidityMessages[i]
							.timestamp;
					}
					continue;
				}
			}
		}

		if (!isMainChain()) {
			SupplyMessage[] memory _supplyMessages = new SupplyMessage[](
				tokenInfo.length
			);
			LiquidityMessage[]
				memory _liquidityMessages = new LiquidityMessage[](
					tokenInfo.length
				);
			for (uint256 i = 0; i < tokenInfo.length; i++) {
				if (chainId == tokenInfo[i]._chainId) {
					_supplyMessages[i] = SupplyMessage(
						tokenInfo[i]._address,
						_totalSupplies[i],
						chainId,
						block.timestamp
					);
					_liquidityMessages[i] = LiquidityMessage(
						tokenInfo[i]._address,
						_liquidities[i],
						chainId,
						block.timestamp
					);
				}
			}
		}
	}

	function checkTokenParams() public {
		for (uint256 i = 0; i < tokenInfo.length; i++) {
			if (
				block.timestamp - tokenParamsTimestampUpdates[i] >= timeWindow
			) {
				liquidities[i] = liquidityManager.getTotalLiquidityForToken(
					tokenInfo[i]._address
				);
				totalSupplies[i] = IERC20(tokenInfo[i]._address).totalSupply();
				tokenParamsTimestampUpdates[i] = block.timestamp;
			}
		}
	}

	function _lzReceive(
		Origin calldata /*_origin*/,
		bytes32 /*_guid*/,
		bytes calldata payload,
		address /*_executor*/,
		bytes calldata /*_extraData*/
	) internal override {
		// data = abi.decode(payload, (string));
		IndexUpdateMessage memory indexMessage = abi.decode(
			payload,
			(IndexUpdateMessage)
		);
		for (uint256 i = 0; i < indexMessage.liquidityMessages.length; i++) {
			LiquidityMessage memory liquidityMessage = indexMessage
				.liquidityMessages[i];
			liquidityMessages.push(liquidityMessage);
		}
		for (uint256 i = 0; i < indexMessage.supplyMessages.length; i++) {
			SupplyMessage memory supplyMessage = indexMessage.supplyMessages[i];
			supplyMessages.push(supplyMessage);
		}
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

	function normalizePrice(
		uint256 price,
		int8 decimals
	) public pure returns (uint256) {
		int8 maxDecimals = 10; // Set maximum decimals to 10

		// Scale the price to the maximum number of decimals
		uint256 normalizedPrice = price *
			(10 ** uint256(uint8(maxDecimals - decimals)));

		return normalizedPrice;
	}

	function collectPriceFeeds() external {
		require(
			block.timestamp - lastSampleTime >= samplingFrequency,
			"IndexAggregator: Sampling frequency not reached"
		);

		(
			uint256[] memory feedValues,
			int8[] memory decimals,
			uint64 timestamp
		) = getFtsoV2CurrentFeedValues();

		// we can use the timestamp to check if the price is stale
		// if (timestamp - lastSampleTime >= timeWindow) {

		if (block.timestamp - lastSampleTime >= timeWindow) {
			for (uint256 i = 0; i < tokenInfo.length; i++) {
				if (movingAverage[i].length > 0) {
					movingAverage[i].pop();
				}
			}
		}

		for (uint256 i = 0; i < tokenInfo.length; i++) {
			uint256 normalisedPrice = normalizePrice(
				feedValues[i],
				decimals[i]
			);
			movingAverage[i].push(uint256(normalisedPrice));
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

	function persistIndex(
		uint256[] memory indexOrders,
		string memory tag
	) public returns (bool) {
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
		// if (
		// 	keccak256(abi.encodePacked(tag)) != keccak256(abi.encodePacked(""))
		// ) {
		// 	tagsIndexOrder[tag] = indexOrders;
		// } else {
		// 	lastIndexOrder = indexOrders;
		// 	lastIndexTimestamp = block.timestamp;
		// }
		return true;
	}

	function quote(
		uint32 _dstEid,
		string memory _message,
		bytes memory _options,
		bool _payInLzToken
	) public view returns (MessagingFee memory fee) {
		bytes memory payload = abi.encode(_message);
		fee = _quote(_dstEid, payload, _options, _payInLzToken);
	}

	function send(
		uint32 _dstEid,
		bytes memory _options,
		IndexUpdateMessage memory data
	) external payable returns (MessagingReceipt memory receipt) {
		bytes memory _payload = abi.encode(data);
		receipt = _lzSend(
			_dstEid,
			_payload,
			_options,
			MessagingFee(msg.value, 0),
			payable(msg.sender)
		);
	}
}
