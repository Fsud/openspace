// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/proxy/Clones.sol";
import {MiniERC20} from "./MiniERC20.sol";

/**
 * 要求：
 *
 *     包含测试用例：
 *     费用按比例正确分配到发行者账号及项目方账号。
 *     每次发行的数量正确，且不会超过 totalSupply.
 *     请包含运行测试的截图或日志
 */

 struct Inscription {
    string symbol;
    uint256 totalSupply;
    uint256 minted;
    uint256 price;
    uint256 perMint;
    address owner;
    address token;
}

contract ERC20CloneFactory{

    MiniERC20 public erc20;

    mapping(address => Inscription) public inscriptions; // erc20 address => Inscription

    address payable public admin;

    uint8 fee;  //percentage of mintfee to admin

    event Clone(address indexed sender, address token);

    event Mint(address indexed token, address indexed sender);

    constructor(uint8 _fee) {
        erc20 = new MiniERC20();
        admin = payable(msg.sender);
        require(fee < 100, "fee big than 100");
        fee = _fee;
    }

    /**
     * ⽤户调⽤该⽅法创建 ERC20 Token合约，symbol 表示新创建代币的代号（ ERC20 代币名字可以使用固定的），
     *     totalSupply 表示总发行量， perMint 表示单次的创建量， price 表示每个代币铸造时需要的费用（wei 计价）。
     *     每次铸造费用在扣除手续费后（手续费请自定义）由调用该方法的用户收取。
     */
    function deployInscription(string calldata symbol, uint256 totalSupply, uint256 perMint, uint256 price) public returns (address token){
        MiniERC20 copy = MiniERC20(Clones.clone(address(erc20)));
        copy.initialize(address(this), symbol, totalSupply);
        emit Clone(msg.sender, address(copy));

        Inscription memory inscription = Inscription({
            symbol: symbol,
            totalSupply: totalSupply,
            minted: 0,
            price: price,
            perMint:perMint,
            owner: msg.sender,
            token: address(copy)
        });
        inscriptions[address(copy)] = inscription;
        return address(copy);
    }

    /**
     * 每次调用发行创建时确定的 perMint 数量的 token，并收取相应的费用。
     */
    function mintInscription(address tokenAddr) public payable {
        Inscription storage inscription = inscriptions[tokenAddr];
        require(inscription.token != address(0),"not exist tokenAddr");
        require(inscription.minted + inscription.perMint <= inscription.totalSupply, "mint end");
        require(msg.value >= inscription.price, "price too low");

        MiniERC20 token = MiniERC20(inscription.token);
        token.transfer(msg.sender, inscription.perMint);
        inscription.minted += inscription.perMint;
        payable(inscription.owner).transfer(msg.value * fee / 100);
        payable(admin).transfer(msg.value * (100 - fee) / 100);

        emit Mint(tokenAddr, msg.sender);
    }

    function getInscription(address _erc20) view public returns (Inscription memory inscription){
        return inscriptions[_erc20];
    }
}
