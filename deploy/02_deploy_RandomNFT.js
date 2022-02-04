const {networkConfig} = require("../helper-hardhat-config");

module.exports = async({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    const {deploy, log, get} = deployments;
    const {deployer} = await getNamedAccounts();
    const chainId = await getChainId();

    let linkTokenAddress, vrfCoordinatorMockAddress;
    if(chainId == 31337){
        let linkToken = await get('LinkToken');
        linkTokenAddress = linkToken.address;
        let vrfCoordinatorMock = await get('VRFCoordinatorMock');
        vrfCoordinatorMockAddress = vrfCoordinatorMock.address;
    }
    else{
        linkTokenAddress = networkConfig[chainId]['linkToken'];
        vrfCoordinatorMockAddress = networkConfig[chainId]['vrfCoordinator'];
    }
    const keyHash = networkConfig[chainId]['keyHash'];
    const fee = networkConfig[chainId]['fee'];
    let args = [vrfCoordinatorMockAddress, linkTokenAddress, keyHash, fee];
    log("----------------------------------------------------");
    const RandomSVG = await deploy('RandomSVG', {from: deployer, args: args, log: true});
    log("Random NFT deployed!!");
    const networkName = networkConfig[chainId]['name'];
    log(`verify using: \nnpx hardhat verify --network ${networkName} ${RandomSVG.address} ${args.toString().replace(/,/g, " ")}`)

    const linkTokenContract = await ethers.getContractFactory('LinkToken');
    const accounts = await hre.ethers.getSigners();
    const signer = accounts[0];
    const linkToken = new ethers.Contract(linkTokenAddress, linkTokenContract.interface, signer);
    let fund_tx = await linkToken.transfer(RandomSVG.address, '200000000000000');
    await fund_tx.wait(1);

    const randomSVGContract = await ethers.getContractFactory('RandomSVG');
    const randomSVG = new ethers.Contract(RandomSVG.address, randomSVGContract.interface, signer);
    let create_tx = await randomSVG.create({gasLimit: 300000});
    let receipt = await create_tx.wait(1);
    let tokenId = receipt.events[3].topics[2];
    log(`${tokenId}`);
    log(`Created an  NFT with tokenId ${tokenId.toString()}`);
    log(`Waiting for chainlink to respond...`);

    if(chainId != 31337){
        await new Promise(r => setTimeout(r, 180000))
        log(`Now lets finish the mint!`);
        let finish_tx = await randomSVG.finishMint(tokenId, {gasLimit: 2000000, gasPrice: '20000000000'})
        await finish_tx.wait(1);
        log(`You can view the Token here:\n ${await randomSVG.tokenURI(tokenId)}`)
    }else{
        const vrfCoordinator = await ethers.getContractAt("VRFCoordinatorMock", vrfCoordinatorMockAddress, signer);
        const vrf_tx = await vrfCoordinator.callBackWithRandomness(receipt.logs[3].topics[1], 476473, RandomSVG.address)
        await vrf_tx.wait(1);
        log("Now lets finish the mint!");
        let finish_tx =  await randomSVG.finishMint(tokenId, {gasLimit: 2000000})
        await finish_tx.wait(1);
        log(`You can view the Token here:\n ${await randomSVG.tokenURI(tokenId)}`)
    }


}

module.exports.tags = ['all', 'rsvg'];
