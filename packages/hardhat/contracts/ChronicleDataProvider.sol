// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IChronicle.sol";
import "./IDataProvider.sol";
import { IERC20 } from "./IERC20.sol";

interface ISelfKisser {
	/// @notice Kisses caller on oracle `oracle`.
	function selfKiss(address oracle) external;
}

contract ChronicleDataProvider is IDataProvider {
	/// @notice The token to read data for.
	address public token;
	/// @notice The Chronicle oracle to read from.
	IChronicle public chronicle =
		IChronicle(address(0xdd6D76262Fd7BdDe428dcfCd94386EbAe0151603));
	/// @notice The chain ID of the network.
	uint32 public chainId;

	/// @notice The SelfKisser granting access to Chronicle oracles.
	ISelfKisser public selfKisser =
		ISelfKisser(address(0x0Dcc19657007713483A5cA76e6A7bbe5f56EA37d));

	constructor(address _token, uint32 _chainId) {
		// Note to add address(this) to chronicle oracle's whitelist.
		// This allows the contract to read from the chronicle oracle.
		selfKisser.selfKiss(address(chronicle));
		chainId = _chainId;
		token = _token;
	}

	/// @notice Function to read the latest data from the Chronicle oracle.
	/// @return val The current value returned by the oracle.
	/// @return age The timestamp of the last update from the oracle.
	function read() external view returns (uint256 val, uint256 age) {
		(val, age) = chronicle.readWithAge();
	}

	function getLabel() external view override returns (string memory) {
		return string(abi.encodePacked("priceChronicle", IERC20(token).name()));
	}

	function getMetricData(
		address tokenA
	) external view override returns (uint256) {
		require(tokenA == token, "Invalid token address");
		(uint256 val, ) = chronicle.readWithAge();
		return val;
	}

	function getDataTimestamp() external view override returns (uint256) {
		(, uint256 age) = chronicle.readWithAge();
		return age;
	}

	function getTags() external view override returns (string[] memory) {
		string[] memory tags = new string[](4);
		tags[0] = "partner";
		tags[1] = "chronicle";
		tags[2] = "price";
		tags[3] = IERC20(token).name();
	}

	function getDataType() external pure returns (DataTypes) {
		return DataTypes.PRICE;
	}

	function getAssetAddress() external view override returns (address) {
		return token;
	} 
	
	function getChainId() external view override returns (uint32) { return chainId; }
}
