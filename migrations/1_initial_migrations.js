const sETH = artifacts.require("sETH");
const sBNB = artifacts.require("sBNB");
const BridgeEth = artifacts.require("EthBridge");
const BridgeBnc = artifacts.require("BncBridge");
const LiquidityToken = artifacts.require("LiquidityToken")
const LiquidityPool = artifacts.require("LiquidityPool")


module.exports = async function (deployer, network, addresses) {
    console.log(
        `Deployer address is ${addresses[0]}\n`
    );
    await deployer.deploy(LiquidityToken);
    const liquidityToken = await LiquidityToken.deployed();
    console.log(
        `Deployed LiquidityToken at ${liquidityToken.address}\n`
    );

    let bridgeToken, bridge;

    if(network == 'eth') {
        await deployer.deploy(sETH, addresses[0]);
        bridgeToken = await sETH.deployed();

        await deployer.deploy(BridgeEth, bridgeToken.address);
        bridge = await BridgeEth.deployed();
    } else {
        await deployer.deploy(sBNB, addresses[0]);
        bridgeToken = await sBNB.deployed();

        await deployer.deploy(BridgeBnc, bridgeToken.address);
        bridge = await BridgeBnc.deployed();
    }

    await deployer.deploy(LiquidityPool, bridgeToken.address, liquidityToken.address);
    const liquidityPool = await LiquidityPool.deployed();

    await bridgeToken.mint(addresses[0], web3.utils.toWei('100', 'ether'));

    console.log(`
            Deployed contracts in ${network}:
            - bridge ${bridge.address} 
            - bridgeToken ${bridgeToken.address}
            - liquidityToken ${liquidityToken.address}
            - liquidityPool ${liquidityPool.address}
    `);

    await bridgeToken.transferOwnership(bridge.address);
    await liquidityToken.transferOwnership(liquidityPool.address);
    
    if (network == 'eth') {
        await bridgeToken.approve(liquidityPool.address, web3.utils.toWei('50', 'ether'));
        await liquidityPool.provideLiquidity(web3.utils.toWei('50', 'ether'), { value: web3.utils.toWei('50', 'ether')});
    }
};