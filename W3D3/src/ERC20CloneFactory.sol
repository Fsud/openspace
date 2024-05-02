// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;
import "@openzeppelin/contracts/proxy/Clones.sol";


contract ERC20CloneFactory {


    /** 
        ⽤户调⽤该⽅法创建 ERC20 Token合约，symbol 表示新创建代币的代号（ ERC20 代币名字可以使用固定的），
        totalSupply 表示总发行量， perMint 表示单次的创建量， price 表示每个代币铸造时需要的费用（wei 计价）。
        每次铸造费用在扣除手续费后（手续费请自定义）由调用该方法的用户收取。
    */
    function deployInscription(string calldata symbol, uint totalSupply, uint perMint, uint price) public {

    }

    /**
        每次调用发行创建时确定的 perMint 数量的 token，并收取相应的费用。
     */
    function mintInscription(address tokenAddr) public payable{

    }

}