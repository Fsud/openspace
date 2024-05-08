// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";


contract MyTransparentProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _admin, bytes memory _data) TransparentUpgradeableProxy(_logic, _admin, _data) {}

    function getAdmin() public returns (address) {
        return super._proxyAdmin();
    }

    // function upgradeToAndCall(address addr, bytes calldata data) external payable{
    //     (bool fail, bytes memory err) = super.call(abi.encodeWithSelector(ITransparentUpgradeableProxy.upgradeToAndCall.selector, addr, data));
    // }



}
