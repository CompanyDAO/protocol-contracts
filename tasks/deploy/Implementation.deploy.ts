import { task } from "hardhat/config";

task("deploy:implementation", "Deploy implementation")
  .addOptionalParam("contract", "Contract implementation name", "Service")
  .setAction(async function (
    { contract },
    { getNamedAccounts, deployments: { deploy } }
) {
    const { deployer } = await getNamedAccounts();

    const implementation = await deploy(`${contract}Implementation`, {
        contract,
        from: deployer,
        args: [],
        log: true,
    });

    console.log(`${contract} implementation deployed to ${implementation.address}`);

    return implementation;
});
