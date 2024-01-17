const sBNB = artifacts.require('./sBNB.sol');

module.exports = async done => {
  const [sender, _] = await web3.eth.getAccounts();
  const token = await sBNB.deployed();
  const balance = await token.balanceOf(sender);

  console.log(balance.toString());
  done();
}