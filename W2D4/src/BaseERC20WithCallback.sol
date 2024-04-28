// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseERC20.sol";

interface TokenRecipient {
    function tokensReceived(address sender, uint256 value, bytes memory data) external returns (bool);
}

contract BaseERC20WithCallback is BaseERC20 {
    constructor(string memory _name, string memory _symbol) BaseERC20(_name, _symbol) {}

    //bytes memory data = abi.encode(_tokenId);
    //用户调用此方法，一步直接实现NftMarket的购买
    function transferCallback(address _to, uint256 _value, bytes memory data) public returns (bool success) {
        bool r = super.transfer(_to, _value);
        if (isContract(_to)) {
            TokenRecipient(_to).tokensReceived(msg.sender, _value, data);
        }
        return r;
    }

    // copy from openzepplin
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
