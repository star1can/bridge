const sETH = artifacts.require('./sETH.sol');

module.exports = async done => {
  const [sender, _] = await web3.eth.getAccounts();
  const token = await sETH.deployed();
  const balance = await token.balanceOf(sender);

  console.log(balance.toString());
  done();
}