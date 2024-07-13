// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IDataProvider {
    function getLabel() external view returns (string memory);
    function getMetricData(address tokenA) external view returns (uint256);
    function getTags() external view returns (string[] memory);
    function getDataTimestamp() external view returns (uint256);
}
