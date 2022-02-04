// SPDX_License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "base64-sol/base64.sol";
import "hardhat/console.sol";

contract RandomSVG is ERC721URIStorage, VRFConsumerBase{
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public tokenCounter;
    uint256 public maxLines;
    uint256 public size;
    string[] public colors;

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    event requestedRandomSVG(bytes32 indexed requestId, uint256 indexed tokenId);
    event createdUnfinishedRandomSVG(uint256 indexed tokenId, uint256 randomNumber);
    event createdRandomSVG(uint256 indexed tokenId, string tokenURI);

    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee) 
    VRFConsumerBase(_vrfCoordinator, _linkToken) 
    ERC721("randomlines", "rLINE") {
        keyHash = _keyHash;
        fee = _fee;
        maxLines = 10;
        size = 500;
        colors = ["green", "black", "red", "blue", "white"];
    }

    function create() public returns (bytes32 requestId) {
        requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;
        uint256 tokenId = tokenCounter;
        requestIdToTokenId[requestId] = tokenId;
        tokenCounter += 1;
        emit requestedRandomSVG(requestId, tokenId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        address nftOwner = requestIdToSender[requestId];
        uint256 tokenId = requestIdToTokenId[requestId];
        _safeMint(nftOwner, tokenId);
        tokenIdToRandomNumber[tokenId] = randomNumber;
        emit createdUnfinishedRandomSVG(tokenId, randomNumber);
    }

    function finishMint(uint256 tokenId) public {
        require(bytes(tokenURI(tokenId)).length <= 0, "Token URI already set!");
        require(tokenId < tokenCounter, "Token ID greater than counter");
        require(tokenIdToRandomNumber[tokenId] > 0, "Wait for Chainlink VRF");
        uint256 randomNumber = tokenIdToRandomNumber[tokenId];
        string memory svg = generateSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        string memory tokenURI = formatTokenURI(imageURI);
        _setTokenURI(tokenId, tokenURI);
        emit createdRandomSVG(tokenId, tokenURI);
    }

    function generateSVG(uint256 randomNumber) public view returns(string memory finalSVG){
        uint256 numberOfLines = (randomNumber %  maxLines) + 1;
        console.log("number of lines in NFT are %s", numberOfLines);
        finalSVG = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg'", " height='", uint2str(size), "' width='", uint2str(size), "'>"));
        for(uint256 i=0; i<numberOfLines; i++){
            string memory oneLine = generateLine(randomNumber, i);
            finalSVG = string(abi.encodePacked(finalSVG, oneLine));
        }
        finalSVG = string(abi.encodePacked(finalSVG, "</svg>"));
        console.log("Your Final SVG is: %s", finalSVG);
    }

    function generateLine(uint256 randomNumber, uint256 _i) public view returns(string memory line){
        uint256 colorIndex = (uint256(keccak256(abi.encodePacked(randomNumber, size*2)))) % colors.length;
        uint256 x1 = (uint256(keccak256(abi.encode(randomNumber, _i))) % size) + 1;
        uint256 y1 = (uint256(keccak256(abi.encode(randomNumber, _i+1))) % size) + 1;
        uint256 x2 = (uint256(keccak256(abi.encode(randomNumber, _i+2))) % size) + 1;
        uint256 y2 = (uint256(keccak256(abi.encode(randomNumber, _i+3))) % size) + 1;
        line = string(abi.encodePacked("<line x1='", uint2str(x1), "' y1='", uint2str(y1), "' x2='", uint2str(x2), "' y2='", uint2str(y2), "' stroke='", colors[colorIndex], "'/>"));
    }

    function svgToImageURI (string memory svg) pure internal returns(string memory) {
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

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}