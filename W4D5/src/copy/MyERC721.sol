// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyERC721 is ERC721URIStorage{

    //nft1 pic ipfs://QmSnq6izJgHpP988D3qHosXQMXW1r7wJpV8F88cgQaZ7vc/NFT1.jpg
    //nft2 pic ipfs://QmSnq6izJgHpP988D3qHosXQMXW1r7wJpV8F88cgQaZ7vc/NFT2.jpg

    //nft1 uri ipfs://QmPscDy1PJZGCtCv7mqVyPWA3CLnNZ96jYmkV2rdpraXCQ/NFT1.json
    //nft2 url ipfs://QmfSF8wxpuWFpUqrwWo674k8FFkdohQrZH97FE3juCADWp/NFT2.json

    uint256 public id ;


    constructor() ERC721("openspace", "openspace"){}


    function mint(address receiver, string memory uri) public{
        _mint(receiver, ++id);
        _setTokenURI(id, uri);

    }

}