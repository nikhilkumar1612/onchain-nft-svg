//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";

contract SVGNFT is ERC721URIStorage{
    uint256 public tokenCounter;
    event CreatedNFT(uint256 indexed tokenId, string tokenURI);
    constructor() ERC721("lines", "LINE") {
        tokenCounter=0;
    }

    function create(string memory svg) public {
        _safeMint(msg.sender, tokenCounter);
        string memory imageURI = setImageURI(svg);
        string memory tokenURI = formatTokenURI(imageURI);
        _setTokenURI(tokenCounter, tokenURI);
        emit CreatedNFT(tokenCounter, tokenURI);
        tokenCounter += 1;
    }

    function setImageURI (string memory svg) pure internal returns(string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function formatTokenURI (string memory imageURI) pure internal returns(string memory){
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(abi.encodePacked('{"name": "lines", "description": "An NFT based on SVG!", "attributes": "", "image": "', imageURI, '"}')))
            )
        );
    }
}