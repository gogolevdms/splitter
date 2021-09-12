// npx hardhat run --network rinkeby scripts/deploy.js
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
    const Splitter = await hre.ethers.getContractFactory("Splitter");
    const [deployer, ...acc] = await ethers.getSigners();

    console.log('Deploying contracts with the account:', deployer.address);
    console.log('Account balance:', (await deployer.getBalance()).toString());

    let payees = [];
    let shares = [];

    if (network === 'hardhat') {
        let share1 = '50';
        let share2 = '31';
        let share3 = '19';

        payees.push(acc[0].address);
        payees.push(acc[1].address);
        payees.push(acc[2].address);

        shares.push(share1);
        shares.push(share2);
        shares.push(share3);
    } else if (network === 'rinkeby') {
        payees.push(process.env.PAYEE_RINKEBY_1);
        shares.push(process.env.SHARE_RINKEBY_1);

        payees.push(process.env.PAYEE_RINKEBY_2);
        shares.push(process.env.SHARE_RINKEBY_2);

        payees.push(process.env.PAYEE_RINKEBY_3);
        shares.push(process.env.SHARE_RINKEBY_3);
    } else {
        console.log("Bad network");
    }

    const splitter = await Splitter.deploy(
        payees,
        shares
    );

    console.log("Splitter deployed to:", splitter.address);

    if (network === 'rinkeby') {
        await hre.run("verify:verify", {
            address: splitter.address,
            constructorArguments: [
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
