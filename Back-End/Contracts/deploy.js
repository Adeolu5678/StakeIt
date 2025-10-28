const { Client, PrivateKey, AccountCreateTransaction, AccountBalanceQuery, Hbar, ContractCreateTransaction, FileCreateTransaction, FileAppendTransaction, ContractExecuteTransaction } = require('@hashgraph/sdk');
const fs = require('fs');
require('dotenv').config();

async function main() {
  // Configure Hedera client
  const client = Client.forTestnet();

  // Set operator account (replace with your account details)
  const operatorId = process.env.HEDERA_ACCOUNT_ID;
  const operatorKey = PrivateKey.fromString(process.env.HEDERA_PRIVATE_KEY);

  client.setOperator(operatorId, operatorKey);

  console.log('Deploying StakeIt contract to Hedera testnet...');

  try {
    // Read contract bytecode
    const contractBytecode = fs.readFileSync('./StakeIt.bin');

    // Create file for contract bytecode
    console.log('Creating contract file...');
    const fileCreateTx = new FileCreateTransaction()
      .setContents(contractBytecode)
      .setKeys([operatorKey])
      .setMaxTransactionFee(new Hbar(2))
      .freezeWith(client);

    const fileCreateSign = await fileCreateTx.sign(operatorKey);
    const fileCreateSubmit = await fileCreateSign.execute(client);
    const fileCreateRx = await fileCreateSubmit.getReceipt(client);
    const bytecodeFileId = fileCreateRx.fileId;

    console.log(`Contract bytecode file created: ${bytecodeFileId}`);

    // Deploy contract
    console.log('Deploying contract...');
    const contractInstantiateTx = new ContractCreateTransaction()
      .setBytecodeFileId(bytecodeFileId)
      .setGas(100000)
      .setConstructorParameters([
        // Constructor parameters: charityWallet, platformWallet, liquidityReserve
        process.env.CHARITY_WALLET || '0x0000000000000000000000000000000000000000',
        process.env.PLATFORM_WALLET || '0x0000000000000000000000000000000000000000',
        process.env.LIQUIDITY_RESERVE || '0x0000000000000000000000000000000000000000'
      ])
      .setMaxTransactionFee(new Hbar(16));

    const contractInstantiateSubmit = await contractInstantiateTx.execute(client);
    const contractInstantiateRx = await contractInstantiateSubmit.getReceipt(client);
    const contractId = contractInstantiateRx.contractId;

    console.log(`Contract deployed successfully!`);
    console.log(`Contract ID: ${contractId}`);
    console.log(`Contract Address: ${contractId.toSolidityAddress()}`);

    // Grant oracle role
    if (process.env.ORACLE_ADDRESS) {
      console.log('Granting ORACLE_ROLE...');
      const grantRoleTx = await new ContractExecuteTransaction()
        .setContractId(contractId)
        .setGas(80000)
        .setFunction("grantRole", [
          "0x" + Buffer.from("ORACLE_ROLE").toString('hex').padStart(64, '0'),
          process.env.ORACLE_ADDRESS
        ])
        .setMaxTransactionFee(new Hbar(5))
        .execute(client);

      const grantRoleRx = await grantRoleTx.getReceipt(client);
      console.log(`Oracle role granted. Transaction: ${grantRoleRx.transactionId}`);
    }

    // Save deployment info
    const deploymentInfo = {
      contractId: contractId.toString(),
      contractAddress: contractId.toSolidityAddress(),
      deployer: operatorId,
      network: 'testnet',
      timestamp: new Date().toISOString(),
      bytecodeFileId: bytecodeFileId.toString()
    };

    fs.writeFileSync('./deployment.json', JSON.stringify(deploymentInfo, null, 2));
    console.log('Deployment info saved to deployment.json');

  } catch (error) {
    console.error('Deployment failed:', error);
    process.exit(1);
  }

  client.close();
}

main();