const networkConfig = {
    31337: {
        name: 'localhost',
        keyHash: '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311',
        fee: '100000000000000000'
    },
    4: {
        name: 'rinkeby',
        linkToken: '0x01BE23585060835E02B77ef475b0Cc51aA1e0709',
        vrfCoordinator: '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B',
        keyHash: '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311',
        fee: '100000000000000000'
    },
    80001: {
        name: 'polygon',
        linkToken: '0x326C977E6efc84E512bB9C30f76E30c160eD06FB',
        vrfCoordinator: '0x8C7382F9D8f56b33781fE506E897a4F1e2d17255',
        keyHash: '0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4',
        fee: '100000000000000'
    }
}

module.exports = {networkConfig}