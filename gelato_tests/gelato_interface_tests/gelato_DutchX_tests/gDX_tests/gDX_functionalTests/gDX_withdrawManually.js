/* eslint-disable indent */
const Gelato = artifacts.require('Gelato');
const EtherToken = artifacts.require('EtherToken')
const RDNToken = artifacts.require('TokenRDN')

// Command line arguments
const sellOrderHash = process.argv[4];

// const EtherToken = contract(require('@gnosis.pm/util-contracts/build/contracts/EtherToken'))

module.exports = async () => {

    // Variables
    // const seller = '0x627306090abab3a6e1400e9345bc60c78a8bef57'
    const accounts = await web3.eth.getAccounts()
    const seller = accounts[9]
    const RDNaddress = RDNToken.address
    const WETHaddress = EtherToken.address
    const RDN = await RDNToken.at(RDNaddress)
    const gelato = await Gelato.at(Gelato.address)

    console.log('...Starting execute sub-order script')
    console.log('----')
    const block = await web3.eth.getBlockNumber()
    const blockDetails = await web3.eth.getBlock(block)
    const timestamp = blockDetails.timestamp
    console.log(`Current Timestamp:                  ${timestamp}`)
    console.log(`
        ==================================================
    `)

    console.log(`Seller:                             ${seller}`)
    const RDNbalance = await RDN.balanceOf(seller)
    console.log(`Sellers RDN balance before:         ${RDNbalance / (10 ** 18)}`)

    console.log(`Withdraw Funds...`)
    const txReceipt = await gelato.withdrawManually(sellOrderHash, { from: seller })


    const RDNbalance2 = await RDN.balanceOf(seller)
    console.log(`Sellers RDN balance after:          ${RDNbalance2 / (10 ** 18)}`)
    const difference = RDNbalance2 - RDNbalance
    console.log(`
        ==================================================
    `)
    console.log(`Difference:                         ${difference / (10 ** 18)}`)

    // ####### TESTS

    // LogNumDen
    const num = txReceipt.logs[0].args.num.toString(10)
    const den = txReceipt.logs[0].args.den.toString(10)

    // LogWithdrawAmount
    const withdrawAmount = txReceipt.logs[1].args.withdrawAmount.toString(10)

    // LogWithdrawAmount
    const sellerLog = txReceipt.logs[2].args.seller
    const withdrawAmount2 = txReceipt.logs[2].args.withdrawAmount.toString(10)
    const token = txReceipt.logs[2].args.token.toString(10)


    // console.log(executeSubOrder)
    console.log('Withdraw by seller successfully executed')

    // console.log(withdrawManually)
}