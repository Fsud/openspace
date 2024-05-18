// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import "./uni-core/interfaces/IUniswapV2Pair.sol";

library MyLibrary {
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path)
        public
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "invalid path");
        amounts = new uint256[](path.length); //n个路径节点，有n个amount
        amounts[0] = amountIn;
        for (uint256 i = 0; i < path.length - 1; i++) {
            (uint256 reserveA, uint256 reserveB) = getReserves(factory, path[i], path[i + 1]);
            //上一个路径的输出，是下一个的输入
            amounts[i + 1] = getAmountOut(amounts[i], reserveA, reserveB);
        }
    }

    //曲线上移动，面积不变公式
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn != 0 && reserveIn != 0 && reserveOut != 0, "invalid input");
        uint256 amountInWithFee = amountIn * 997;
        return amountOut = amountInWithFee * reserveOut / (reserveIn * 1000 + amountInWithFee); 
    }

    function getReserves(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "tokenA must not equal tokenB");
        return (tokenA < tokenB) ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * 这个方法是COPY的
     */
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"32ad4c8d67b64e69b86acb871624603ea5aad1accb790cf8c5ef3958c4e24e88"
                        )
                    )
                )
            )
        );
    }
}
