const { network } = require('hardhat');

module.exports = async (hre) => {
    const { getNamedAccounts, deployments } = hre;
    const { deployer } = await getNamedAccounts();
    const { deploy, log } = deployments;
    const chainId = network.config.chainId;
    let vrfCoordinatorV2Address, subscriptionId;

    const FUND_AMOUNT = 10000000000000000000;

    const tokenUris = [
        'https://ipfs.io/ipfs/QmYcrRfQX1CiXn17vens9dMjBr1JFGccXm51LsKztWxGPD?filename=0-Pug.json',
        'https://ipfs.io/ipfs/QmY746h8Nreyn9yJovmMv91NEiXAfcvUxZSjUmaegsPiJE?filename=1-Shiba.json',
        'https://ipfs.io/ipfs/QmPQFkNnXXbAQjaC6LzQ5uivBgFztPpVwJjRWJgBLqNPz4?filename=3-st-bernard.json',
    ];

    if (chainId == 31337) {
        // make a fake chainlink VRF Node
        const vrfCoordinatorV2Mock = await ethers.getContract(
            'VRFCoordinatorV2Mock'
        );
        vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address;

        const tx = await vrfCoordinatorV2Mock.createSubscription();
        const txReceipt = await tx.wait(1);

        subscriptionId = txReceipt.events[0].args.subId;
        await vrfCoordinatorV2Mock.fundSubscriptionId(
            subscriptionId,
            FUND_AMOUNT
        );
    } else {
        // use the real ones
        vrfCoordinatorV2Address = '0x6168499c0cFfCaCD319c818142124B7A15E857ab';
        subscriptionId = '3672';
    }

    args = [
        vrfCoordinatorV2Address,
        '0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc',
        subscriptionId,
        '500000',
        tokenUris, // list of dogs
    ];

    const randomIpfsNft = await deploy('RandomIpfsNft', {
        from: deployer,
        args: args,
        log: true,
    });
    console.log(randomIpfsNft.address);
};
