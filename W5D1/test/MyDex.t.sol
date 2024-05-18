pragma solidity ^0.8.25;

import "../src/MyDex.sol";
import {UniswapV2Router02} from "../src/UniswapV2Router02.sol";
import {UniswapV2Factory} from "../src/uni-core/UniswapV2Factory.sol";
import {WETH9} from "../src/WETH9.sol";
import {Test, console2} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract MyDexTest is Test {
    MyDex myDex;
    // UniswapV2Router02 uniswapRouter;
    IUniswapV2Factory uniswapFactory;
    WETH9 weth;
    RNTToken rnt;
    address payable feeTo;

    function setUp() public {
        feeTo = payable(makeAddr("feeTo"));
        uniswapFactory = new UniswapV2Factory(feeTo);

        weth = new WETH9();
        rnt = new RNTToken();
        vm.deal(address(this), 20 ether);

        myDex = new MyDex(address(uniswapFactory), payable(address(weth)));

        //添加流动性(addLiquidity)没有自己写，直接调用的复制过来的Router合约。
        rnt.approve(address(myDex), 1000 * 1e18);
        myDex.addLiquidity{value: 10 ether}(address(rnt), 1000 * 1e18, 1000 * 1e18, 10 ether); // 添加了10E和1000个RNT
        assertEq(rnt.balanceOf(address(this)), 0);
        assertEq(address(this).balance, 10 ether);

        address pair = uniswapFactory.getPair(address(weth), address(rnt));
        assertEq(rnt.balanceOf(pair), 1000 * 1e18);
        assertEq(weth.balanceOf(pair), 10 ether);
        assertEq(IERC20(pair).balanceOf(address(this)), Math.sqrt(1000 * 1e18 * 10 ether) - 10 ** 3); //添加时自动将1000流动性销毁了
    }

    function test_sellETH() public {
        myDex.sellETH{value: 0.1 ether}(address(rnt), 0); //由于滑点和千分之三手续费，0.1ETH应该能换少于10RNT
        assertLt(rnt.balanceOf(address(this)), 10 * 1e18); //VM::assertLt(9871580343970612988 [9.871e18], 10000000000000000000 [1e19])
    }

    function test_buyETH() public {
        rnt.mint(address(this), 10 * 1e18);
        rnt.approve(address(myDex), 10 * 1e18);
        myDex.buyETH(address(rnt), 10 * 1e18, 0); //由于滑点和千分之三手续费，10RNT应该能换少于0.1ETH
        assertLt(weth.balanceOf(address(this)), 0.1 ether); //VM::assertLt(98715803439706129 [9.871e16], 100000000000000000 [1e17]) [staticcall]
    }

    function test_removeLiquidity() public {
        address pair = uniswapFactory.getPair(address(weth), address(rnt));
        uint256 liquidity = IERC20(pair).balanceOf(address(this));
        IERC20(pair).approve(address(myDex), liquidity);
        myDex.removeLiquidity(address(rnt), liquidity, 0, 0);
        assertLt(rnt.balanceOf(address(this)), 1000 * 1e18); //流动性不能完全取出，由于添加时自动将1000流动性销毁了。会小于
        assertLt(address(this).balance, 20 ether);
    }

    fallback() external payable {}
}

contract RNTToken is ERC20 {
    constructor() ERC20("RNT", "RNT") {
        _mint(msg.sender, 1000 * 1e18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
