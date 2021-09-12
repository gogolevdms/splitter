// npx hardhat verify --network rinkeby DEPLOYED_CONTRACT_ADDRESS "CONSTRUCTOR PARAM 1" "CONSTRUCTOR PARAM 2"

const hre = require("hardhat");
const network = hre.network.name;
const dotenv = require('dotenv');
const fs = require('fs');
const envConfig = dotenv.parse(fs.readFileSync(`.env`));
for (const k in envConfig) {
    process.env[k] = envConfig[k]
}

async function main() {
    let relayerShare;
    let payees = [];
    let shares = [];

    let splitter = "SPLITTER ADDRESS";

    if (network === 'rinkeby') {
        relayerShare = process.env.RELAYER_SHARE_RINKEBY;

        payees.push(process.env.PAYEE_RINKEBY_1);
        shares.push(process.env.SHARE_RINKEBY_1);

        payees.push(process.env.PAYEE_RINKEBY_2);
        shares.push(process.env.SHARE_RINKEBY_2);
    } else {
        console.log("Bad network");
    }

    if (network === 'rinkeby') {
        await hre.run("verify:verify", {
            address: splitter,
            constructorArguments: [
                relayerShare,
                payees,
                shares,
            ],
        });
    }
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
