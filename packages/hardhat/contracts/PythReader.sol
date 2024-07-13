// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "./IDataProvider.sol";
import { IERC20 } from "./IERC20.sol";

contract PythDataProvider is IDataProvider {
	IPyth pyth;
	bytes32 tokenToUsdPriceId;
	address token;
	uint32 chainId;

	constructor(
		address _pyth,
		bytes32 _priceId,
		address _token,
		uint32 _chainId
	) {
		pyth = IPyth(_pyth);
		tokenToUsdPriceId = _priceId;
		token = _token;
		chainId = _chainId;
	}

	function eighteenDecimalsPrice() public view returns (uint256) {
		PythStructs.Price memory price = pyth.getPrice(tokenToUsdPriceId);

		uint pricedecimals = (uint(uint64(price.price)) * (10 ** 18)) /
			(10 ** uint8(uint32(-1 * price.expo)));
		return pricedecimals;
	}

	function getLabel() external view override returns (string memory) {
		return string(abi.encodePacked("pricePyth", IERC20(token).name()));
	}

	function getMetricData() external view override returns (uint256) {
		return eighteenDecimalsPrice();
	}

	function getDataTimestamp() external view override returns (uint256) {
		return block.timestamp;
	}

	function getTags() external view override returns (string[] memory) {
		string[] memory tags = new string[](4);
		tags[0] = "partner";
		tags[1] = "pyth";
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
