// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "./uni-core/UniswapV2Factory.sol";
import "./MyLibrary.sol";
import "./WETH9.sol";
import "./uni-core/interfaces/IUniswapV2Pair.sol";
import {UniswapV2Router02} from "./UniswapV2Router02.sol";
//➤ 部署自己的 UniswapV2 Dex
//➤ 编写 MyDex 合约，任何人都可通过 MyDex 来买卖ETH
//➤ Test合约测试：创建RNT-ETH交易对、添加初始化流动性、移除流动性、使用 RNT兑换 ETH，用 ETH兑换RNT

interface IDex {
    /**
     * @dev 卖出ETH，兑换成 buyToken
     *      msg.value 为出售的ETH数量
     * @param buyToken 兑换的目标代币地址
     * @param minBuyAmount 要求最低兑换到的 buyToken 数量
     */
    function sellETH(address buyToken, uint256 minBuyAmount) external payable;

    /**
     * @dev 买入ETH，用 sellToken 兑换
     * @param sellToken 出售的代币地址
     * @param sellAmount 出售的代币数量
     * @param minBuyAmount 要求最低兑换到的ETH数量
     */
    function buyETH(address sellToken, uint256 sellAmount, uint256 minBuyAmount) external;
}

contract MyDex is IDex {
    UniswapV2Factory public uniswapFactory;
    WETH9 public weth;
    UniswapV2Router02 public router;

    constructor(address factory, address payable _weth) {
        uniswapFactory = UniswapV2Factory(factory);
        weth = WETH9(_weth);
        router = new UniswapV2Router02(address(uniswapFactory), address(weth));
    }

    //参考：function swapExactETHForTokens
    function sellETH(address buyToken, uint256 minBuyAmount) external payable {
        require(msg.value > 0, "infufficient msg.value");
        weth.deposit{value: msg.value}();
        // weth.approve(address(uniswapFactory), msg.value);
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = buyToken;

        uint256[] memory amounts = MyLibrary.getAmountsOut(address(uniswapFactory), msg.value, path);
        require(amounts[amounts.length - 1] >= minBuyAmount, "amounts out too low");
        address pair = MyLibrary.pairFor(address(uniswapFactory), path[0], path[1]);
        weth.transfer(pair, msg.value);

        IUniswapV2Pair(pair).swap(0, amounts[amounts.length - 1], msg.sender, new bytes(0));
    }

    function buyETH(address sellToken, uint256 sellAmount, uint256 minBuyAmount) external {
        IERC20 sellErc20 = IERC20(sellToken);
        require(sellAmount > 0, "infufficient sellAmount");
        require(sellErc20.allowance(msg.sender, address(this)) >= sellAmount, "allowance not enough");
        //IERC20(sellToken).approve(address(this), sellAmount);

        address[] memory path = new address[](2);
        path[0] = sellToken;
        path[1] = address(weth);

        uint256[] memory amounts = MyLibrary.getAmountsOut(address(uniswapFactory), sellAmount, path);
        require(amounts[amounts.length - 1] >= minBuyAmount, "amounts out too low");
        address pair = MyLibrary.pairFor(address(uniswapFactory), path[0], path[1]);
        sellErc20.transferFrom(msg.sender, pair, sellAmount);

        IUniswapV2Pair(pair).swap(amounts[amounts.length - 1], 0, msg.sender, new bytes(0));
    }
    //-----------------------------以下添加、删除流动性功能是调用复制过来的Router合约的方法，没有自己实现-----------------------------

    function addLiquidity(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin)
        external
        payable
    {
        IERC20(token).transferFrom(msg.sender, address(this), amountTokenDesired);
        IERC20(token).approve(address(router), amountTokenDesired);
        router.addLiquidityETH{value: msg.value}(
            token, amountTokenDesired, amountTokenMin, amountETHMin, msg.sender, block.timestamp + 1000
        );
    }

    function removeLiquidity(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin)
        external
        payable
    {
        address pair = MyLibrary.pairFor(address(uniswapFactory), token, address(weth));
        require(IERC20(pair).allowance(msg.sender, address(this)) >= liquidity, "liquidity allowance not enough");
        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).approve(address(router), liquidity);
        router.removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, msg.sender, block.timestamp + 1000);
    }
}
