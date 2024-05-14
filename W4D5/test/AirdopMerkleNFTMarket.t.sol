pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AirdopMerkleNFTMarket} from "../src/AirdopMerkleNFTMarket.sol";
import {MyERC721} from "../src/copy/MyERC721.sol";
import {PermitERC20} from "../src/copy/PermitERC20.sol";
import {SigUtil} from "../src/copy/SigUtil.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AirdopMerkleNFTMarketTest is Test {
    MyERC721 nft;
    PermitERC20 token;
    AirdopMerkleNFTMarket public market;
    SigUtil sigUtil;
    address admin;
    uint256 adminKey;

    function setUp() public {
        adminKey = vm.envUint("PRIVATE_KEY");
        admin = vm.envAddress("ADDRESS");
        nft = new MyERC721();
        token = new PermitERC20();
        token.transfer(admin, 50);
        market = new AirdopMerkleNFTMarket(
            address(token), address(nft), 0x8ba2796aab0dd4398c0a79034d31b5fcf841014222d284b2fc2ab86155d79957
        );
        sigUtil = new SigUtil(token.DOMAIN_SEPARATOR());

        address alice = makeAddr("alice");
        vm.startPrank(alice);
        nft.mint(alice, "");
        nft.approve(address(market), 1);
        market.list(1, 100);
        vm.startPrank(admin);
    }

    function test_permitPrePay() public {
        SigUtil.Permit memory permit = SigUtil.Permit({
            owner: admin,
            spender: address(market),
            value: 50,
            nonce: token.nonces(msg.sender),
            deadline: 1 hours
        });
        bytes32 digest = sigUtil.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminKey, digest);
        market.permitPrePay(50, 1 hours, v, r, s);
        assertEq(token.allowance(admin, address(market)), 50);
    }

    function test_claimNFT() public {
        test_permitPrePay();

        bytes32[] memory merkleProof = new bytes32[](2);
        merkleProof[0] = 0x79a574c4cf104c7028a98deaee7999a9e44ed137ff63dd4fe63e7847a98d8f32;
        merkleProof[1] = 0xf1d0b1cf153a456431509512addf1686becc79f62fe4d32f95c78fa6975c2e91;
        market.claimNFT(50, 1, merkleProof);
        assertEq(nft.ownerOf(1), admin);
    }

    function test_multicall() public {
        bytes[] memory datas = new bytes[](2);

        //copy from test_permitPrePay
        SigUtil.Permit memory permit = SigUtil.Permit({
            owner: admin,
            spender: address(market),
            value: 50,
            nonce: token.nonces(msg.sender),
            deadline: 1 hours
        });
        bytes32 digest = sigUtil.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminKey, digest);
        datas[0] = abi.encodeWithSelector(market.permitPrePay.selector, 50, 1 hours, v, r, s);

        bytes32[] memory merkleProof = new bytes32[](2);
        merkleProof[0] = 0x79a574c4cf104c7028a98deaee7999a9e44ed137ff63dd4fe63e7847a98d8f32;
        merkleProof[1] = 0xf1d0b1cf153a456431509512addf1686becc79f62fe4d32f95c78fa6975c2e91;
        datas[1] = abi.encodeWithSelector(market.claimNFT.selector, 50, 1, merkleProof);

        market.multicall(datas);
        assertEq(nft.ownerOf(1), admin);
    }
}
