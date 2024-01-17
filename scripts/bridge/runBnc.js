require("dotenv").config()

const init = async() => {

    const Web3 = require('web3');
    const BridgeEth = require('../../build/contracts/EthBridge.json');
    const BridgeBsc = require('../../build/contracts/BncBridge.json');

    const web3Eth = new Web3(process.env.ETH_PROVIDER_URL);

    const web3Bsc = new Web3(new Web3.providers.WebsocketProvider(process.env.BNC_PROVIDER_URL_WSS)); 

    const adminPrivKey = process.env.ADMIN_PRIVATE_KEY;

    const { address: admin } = web3Eth.eth.accounts.wallet.add(adminPrivKey);
    
    console.log("Bridge owner:", admin);

    const bridgeEth = new web3Eth.eth.Contract(
        BridgeEth.abi,
        BridgeEth.networks[process.env.ETH_NETWORK_ID].address
    );
    
    console.log("BridgeEth:", bridgeEth.options.address);

    const bridgeBnc = new web3Bsc.eth.Contract(
        BridgeBsc.abi,
        BridgeBsc.networks[process.env.BNC_NETWORK_ID].address
    );

    console.log("BridgeBnc:", bridgeBnc.options.address);

    bridgeBnc.events.Transfer(
        {fromBlock: 'latest', filter: {step: [0, 2]}}
    )
    .on('data', async event => {
        const { owner, amount, nonce, signature, step } = event.returnValues;
        console.log(`Event on BNC happened: ${step}"`);
        
        const tx = step == 0 
            ? bridgeEth.methods.unlock(owner, nonce, amount, signature) 
            : bridgeEth.methods.mint(owner, nonce, amount, signature);

        const [gasPrice, gasCost] = await Promise.all([
            web3Eth.eth.getGasPrice(),
            tx.estimateGas({from: admin}),
        ]);
        
        const data = tx.encodeABI();
        const txData = {
            from: admin,
            to: bridgeEth.options.address,
            data,
            gas: gasCost,
            gasPrice
        };
        
        const receipt = await web3Eth.eth.sendTransaction(txData);
        console.log(`ETH Transaction hash: ${receipt.transactionHash}`);
        console.log(`
            Processed transfer:
            - from ${owner} 
            - amount ${amount} tokens
            - nonce ${nonce}
        `);
    })
    .on('changed', function(event){
        console.log(event);
    })
    .on("connected", function(subscriptionId){
        console.log(subscriptionId);
    })
    .on('error', function(error, receipt) {
        console.log("ERROR! ", error)
    });
}

init();