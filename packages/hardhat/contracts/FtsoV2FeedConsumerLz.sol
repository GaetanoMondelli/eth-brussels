// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import { IFlareContractRegistry } from "@flarenetwork/flare-periphery-contracts/coston2/util-contracts/userInterfaces/IFlareContractRegistry.sol";
import { IFastUpdater } from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFastUpdater.sol";
import { OApp, MessagingFee, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract FtsoV2FeedConsumerLz is OApp {
	IFlareContractRegistry internal contractRegistry;
	IFastUpdater internal ftsoV2;
	// Feed indexes: 0 = FLR/USD, 2 = BTC/USD, 9 = ETH/USD
	uint256[] public feedIndexes = [0, 2, 9];
	string public data = "Nothing received yet.";

	/**
	 * Constructor initializes the FTSOv2 contract.
	 * The contract registry is used to fetch the FTSOv2 contract address.
	 */
	constructor(
		address _endpoint,
		address _delegate
	) OApp(_endpoint, _delegate) {
		contractRegistry = IFlareContractRegistry(
			0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019
		);
		ftsoV2 = IFastUpdater(
			contractRegistry.getContractAddressByName("FastUpdater")
		);
	}

	/**
	 * Get the current value of the feeds.
	 */
	function getFtsoV2CurrentFeedValues()
		external
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

	/**
	 * @notice Sends a message from the source chain to a destination chain.
	 * @param _dstEid The endpoint ID of the destination chain.
	 * @param _message The message string to be sent.
	 * @param _options Additional options for message execution.
	 * @dev Encodes the message as bytes and sends it using the `_lzSend` internal function.
	 * @return receipt A `MessagingReceipt` struct containing details of the message sent.
	 */
	function send(
		uint32 _dstEid,
		string memory _message,
		bytes calldata _options
	) external payable returns (MessagingReceipt memory receipt) {
		bytes memory _payload = abi.encode(_message);
		receipt = _lzSend(
			_dstEid,
			_payload,
			_options,
			MessagingFee(msg.value, 0),
			payable(msg.sender)
		);
	}

	/**
	 * @notice Quotes the gas needed to pay for the full omnichain transaction in native gas or ZRO token.
	 * @param _dstEid Destination chain's endpoint ID.
	 * @param _message The message.
	 * @param _options Message execution options (e.g., for sending gas to destination).
	 * @param _payInLzToken Whether to return fee in ZRO token.
	 * @return fee A `MessagingFee` struct containing the calculated gas fee in either the native token or ZRO token.
	 */
	function quote(
		uint32 _dstEid,
		string memory _message,
		bytes memory _options,
		bool _payInLzToken
	) public view returns (MessagingFee memory fee) {
		bytes memory payload = abi.encode(_message);
		fee = _quote(_dstEid, payload, _options, _payInLzToken);
	}

	/**
	 * @dev Internal function override to handle incoming messages from another chain.
	 * @dev _origin A struct containing information about the message sender.
	 * @dev _guid A unique global packet identifier for the message.
	 * @param payload The encoded message payload being received.
	 *
	 * @dev The following params are unused in the current implementation of the OApp.
	 * @dev _executor The address of the Executor responsible for processing the message.
	 * @dev _extraData Arbitrary data appended by the Executor to the message.
	 *
	 * Decodes the received payload and processes it as per the business logic defined in the function.
	 */
	function _lzReceive(
		Origin calldata /*_origin*/,
		bytes32 /*_guid*/,
		bytes calldata payload,
		address /*_executor*/,
		bytes calldata /*_extraData*/
	) internal override {
		data = abi.decode(payload, (string));
	}
}
