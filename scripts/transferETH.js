const BridgeEth = artifacts.require('./EthBridge.sol');

const privKey = '7f80d633b5a7e141b471a8155f4d8c6406c3ddc60a56e50a640df3232084236b';

module.exports = async done => {
    const nonce = Math.floor(Math.random() * 100000);

    const accounts = await web3.eth.getAccounts();
    const bridgeEth = await BridgeEth.deployed();

    const amount = web3.utils.toWei('100', 'ether');

    const message = web3.utils.soliditySha3(
      {t: 'address', v: accounts[0]},
      {t: 'uint256', v: amount},
      {t: 'uint256', v: nonce},
    ).toString('hex');

    const { signature } = await web3.eth.accounts.sign(
      message, 
      privKey
    );

    console.log(`
      Pending Lock ETH:
        - from ${accounts[0]} 
        - amount ${amount} tokens
        - nonce ${nonce}
        - siganture ${signature}
    `);
    
    await bridgeEth.lock(accounts[0], nonce, signature, { value: amount});

    done();
}