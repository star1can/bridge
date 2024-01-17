const LiquidityPool = artifacts.require('./LiquidityPool.sol');
const BrdigeToken = artifacts.require('./sETH.sol');

module.exports = async done => {
  const [sender, _] = await web3.eth.getAccounts();

  const token = await BrdigeToken.deployed();
  const pool = await LiquidityPool.deployed();

  const amount = web3.utils.toWei('30', 'ether');

  await token.approve(pool.address, amount);
  await pool.exchangeErcToCoin(amount);

  done();
}