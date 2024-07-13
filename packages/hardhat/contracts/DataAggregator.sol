// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LiquidityManager } from "./LiquidityManager.sol";
import { MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";
import { IFlareContractRegistry } from "@flarenetwork/flare-periphery-contracts/coston2/util-contracts/userInterfaces/IFlareContractRegistry.sol";
import { IFastUpdater } from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFastUpdater.sol";
import { IDataProvider, Data, DataTypes } from "./IDataProvider.sol";

uint32 constant CALLBACK_GAS_LIMIT = 4_000_000;

struct TokenInfo {
	string _name;
	address _address;
	uint32 _chainId;
	uint32 _id;
}

struct IndexUpdateMessage {
	Data[] liquidityMessages;
	Data[] supplyMessages;
	Data[] priceMessages;
}

struct AggregatorParams {
	uint256 _timeWindow;
	uint256 _sampleSize;
	uint256 _bribeUnit;
}

error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);

contract DataAggregator is OApp {
	TokenInfo[] public tokenInfo;
	IDataProvider[] public dataProviders;
	TokenInfo[] tmpTokens;
	mapping(string => uint256) public tokens;
	string[] public tokenSymbols;

	uint256[] public totalSupplies;
	uint256[] public liquidities;
	uint256[] public prices;
	uint256[] public tokenParamsTimestampUpdates;

	Data[] public messages;

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

	constructor(
		TokenInfo[] memory _tokenInfo,
		address _endpoint,
		address[] memory _dataProviders,
		AggregatorParams memory _aggregatorParams
	) OApp(_endpoint, msg.sender) {
		sampleSize = _aggregatorParams._sampleSize;
		timeWindow = _aggregatorParams._timeWindow;
		samplingFrequency = timeWindow / sampleSize;
		bribeUnit = _aggregatorParams._bribeUnit;

		for (uint256 i = 0; i < _dataProviders.length; i++) {
			dataProviders.push(IDataProvider(_dataProviders[i]));
		}

		for (uint256 i = 0; i < _tokenInfo.length; i++) {
			tokenInfo.push(_tokenInfo[i]);
			// tokenSymbols.push(_tokenInfo[i]._symbol);
			tokens[_tokenInfo[i]._name] = _tokenInfo[i]._id;
		}

		prices = new uint256[](tokenInfo.length);
		totalSupplies = new uint256[](tokenInfo.length);
		liquidities = new uint256[](tokenInfo.length);
		tokenParamsTimestampUpdates = new uint256[](tokenInfo.length);
	}

	function isMainChain() public view returns (bool) {
		return chainId == mainChainId;
	}

	function isOnSameChain(uint32 _chainId) public view returns (bool) {
		return chainId == _chainId;
	}

	function setChainId(uint32 _chainId, uint32 _mainChainId) external {
		chainId = _chainId;
		mainChainId = _mainChainId;
	}

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

	function _lzReceive(
		Origin calldata /*_origin*/,
		bytes32 /*_guid*/,
		bytes calldata payload,
		address /*_executor*/,
		bytes calldata /*_extraData*/
	) internal override {
		// data = abi.decode(payload, (string));
		Data[] memory inboxMessages = abi.decode(payload, (Data[]));
		for (uint256 i = 0; i < inboxMessages.length; i++) {
			messages.push(inboxMessages[i]);
		}
	}

	function normalizePrice(
		uint256 price,
		int8 decimals
	) public pure returns (uint256) {
		int8 maxDecimals = 18; // Set maximum decimals to 10

		// Scale the price to the maximum number of decimals
		uint256 normalizedPrice = price *
			(10 ** uint256(uint8(maxDecimals - decimals)));

		return normalizedPrice;
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
