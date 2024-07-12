// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./IUniswapV3Factory.sol";
// import "./IUniswapV3Pool.sol";

contract LiquidityManager {
    // IUniswapV3Factory public factory;
    uint24[] public feeTiers = [500, 3000, 10000]; // Example fee tiers: 0.05%, 0.3%, 1% these are Uniswap V3 standards
    address[] public comparisonTokens;

    constructor(address _factory, address[] memory _comparisonTokens) {
        // factory = IUniswapV3Factory(_factory);
        comparisonTokens = _comparisonTokens;
    }

    function getPoolsForToken(address token) public view returns (address[] memory) {
        uint256 poolCount = 0;
        address[] memory tempPools = new address[](comparisonTokens.length * feeTiers.length);

        for (uint256 i = 0; i < comparisonTokens.length; i++) {
            if (comparisonTokens[i] == token) continue;
            for (uint256 j = 0; j < feeTiers.length; j++) {
                // address pool = factory.getPool(token, comparisonTokens[i], feeTiers[j]);
                // if (pool != address(0)) {
                //     tempPools[poolCount] = pool;
                //     poolCount++;
                // }
            }
        }

        // Create an array of the actual size
        address[] memory pools = new address[](poolCount);
        for (uint256 i = 0; i < poolCount; i++) {
            pools[i] = tempPools[i];
        }

        return pools;
    }

    function getTotalLiquidityForToken(address token) public view returns (uint128 totalLiquidity) {
        address[] memory pools = getPoolsForToken(token);
        for (uint256 i = 0; i < pools.length; i++) {
            totalLiquidity += 1;
            // IUniswapV3Pool(pools[i]).liquidity();
        }
    }
}
