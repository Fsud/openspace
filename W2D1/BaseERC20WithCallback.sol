// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './BaseERC20.sol';


contract BaseERC20WithCallback is BaseERC20{


    //bytes memory data = abi.encode(_tokenId);
    //用户调用此方法，一步直接实现NftMarket的购买
    function transferCallback(address _to, uint256 _value, bytes memory data) public returns (bool success) {
        bool r = super.transfer(_to, _value);
        if(isContract(_to)){
            _to.call(abi.encodeWithSignature("tokensReceived(address,uint256,bytes)", msg.sender, _value, data));
        }
        return r;
    }

    // copy from openzepplin
    function isContract(address account) internal view returns (bool) {
        
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}