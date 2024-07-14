// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IFlareContractRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/util-contracts/userInterfaces/IFlareContractRegistry.sol";
import {IFastUpdater} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFastUpdater.sol";
import {IFastUpdatesConfiguration} from "@flarenetwork/flare-periphery-contracts/coston2/ftso/userInterfaces/IFastUpdatesConfiguration.sol";

library FTSOFeedIdConverter {
    function FeedCategoryCrypto() internal pure returns (uint8) {
        return 1;
    }
    function getFeedId(
        uint8 _category,
        string memory _name
    ) internal pure returns (bytes21) {
        bytes memory nameBytes = bytes(_name);
        require(nameBytes.length <= 20, "name too long");
        return bytes21(bytes.concat(bytes1(_category), nameBytes));
    }

    function getCryptoFeedId(
        string memory _name
    ) internal pure returns (bytes21) {
        return
            bytes21(bytes.concat(bytes1(FeedCategoryCrypto()), bytes(_name)));
    }

    function getFeedCategoryAndName(
        bytes21 _feedId
    ) internal pure returns (uint8 _category, string memory _name) {
        _category = uint8(_feedId[0]);
        uint256 length = 20;
        while (length > 0) {
            if (_feedId[length] != 0x00) {
                break;
            }
            length--;
        }
        bytes memory nameBytes = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            nameBytes[i] = _feedId[i + 1];
        }
        _name = string(nameBytes);
    }
}

contract FtsoV2FeedConsumer {
    IFlareContractRegistry internal contractRegistry;
    IFastUpdater internal ftsoV2;
    IFastUpdatesConfiguration internal fastUpdatesConfiguration;
    // Feed indexes: 0 = FLR/USD, 2 = BTC/USD, 9 = ETH/USD
    uint256[] public feedIndexes = [0, 2, 9];

    /**
     * Constructor initializes the FTSOv2 contract.
     * The contract registry is used to fetch the FTSOv2 contract address.
     */
    constructor() {
        contractRegistry = IFlareContractRegistry(
            0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019
        );
        ftsoV2 = IFastUpdater(
            contractRegistry.getContractAddressByName("FastUpdater")
        );
        fastUpdatesConfiguration = IFastUpdatesConfiguration(
            contractRegistry.getContractAddressByName(
                "FastUpdatesConfiguration"
            )
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

    function getFtsoV2CurrentFeedValuesByNames(
        string[] memory _assetName
    )
        external
        view
        returns (
            uint256[] memory _feedValues,
            int8[] memory _decimals,
            uint64 _timestamp
        )
    {
        bytes21[] memory feedIds = new bytes21[](_assetName.length);
        for (uint256 i = 0; i < _assetName.length; i++) {
            feedIds[i] = FTSOFeedIdConverter.getCryptoFeedId(
                string.concat(string(_assetName[i]), string("/USD"))
            );
        }
        uint256[] memory indices = new uint256[](feedIds.length);
        for (uint256 i = 0; i < feedIds.length; i++) {
            indices[i] = fastUpdatesConfiguration.getFeedIndex(feedIds[i]);
        }
        (
            uint256[] memory feedValues,
            int8[] memory decimals,
            uint64 timestamp
        ) = ftsoV2.fetchCurrentFeeds(indices);
        /* Your custom feed consumption logic. In this example the values are just returned. */
        return (feedValues, decimals, timestamp);
    }

    function getFtsoV2CurrentFeedValuesByName(
        string memory _assetName
    )
        external
        view
        returns (
            uint256[] memory _feedValues,
            int8[] memory _decimals,
            uint64 _timestamp
        )
    {
        bytes21[] memory feedIds = new bytes21[](1);

        feedIds[0] = FTSOFeedIdConverter.getCryptoFeedId(
            string.concat(string(_assetName), string("/USD"))
        );

        uint256[] memory indices = new uint256[](feedIds.length);
        for (uint256 i = 0; i < feedIds.length; i++) {
            indices[i] = fastUpdatesConfiguration.getFeedIndex(feedIds[i]);
        }
        (
            uint256[] memory feedValues,
            int8[] memory decimals,
            uint64 timestamp
        ) = ftsoV2.fetchCurrentFeeds(indices);
        /* Your custom feed consumption logic. In this example the values are just returned. */
        return (feedValues, decimals, timestamp);
    }
}
