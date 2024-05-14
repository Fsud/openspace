const { MerkleTree } = require('merkletreejs');
const keccak256 = require("keccak256");
// 生成有资格的白名单和金额列表
const users = [
    { address: "0x11840afa3983516d28b459c547906cfc63dc88a0" },
    { address: "0x4deb6351805215b1c1240d9f9ad0545006d6ddb0" },
    { address: "0xa96d98bfacbb2188edd91ec772f28d90d3fabbc3" },
    { address: "0xff07eA54B66De1774054Ce8B5a084A7943F2B532" },   //my wallet
];
// 编码数据结构
const elements = users.map((x) => keccak256(x.address));
const merkleTree =
    new MerkleTree(elements, keccak256, { sort: true });
// 生成Merkle根
const root = merkleTree.getHexRoot();

console.log(merkleTree.getHexProof(elements[3]));
// ['0x79a574c4cf104c7028a98deaee7999a9e44ed137ff63dd4fe63e7847a98d8f32','0xf1d0b1cf153a456431509512addf1686becc79f62fe4d32f95c78fa6975c2e91']

console.log(root);
//0x8ba2796aab0dd4398c0a79034d31b5fcf841014222d284b2fc2ab86155d79957