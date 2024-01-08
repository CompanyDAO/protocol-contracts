import { task } from "hardhat/config";

task("deploy:beacon", "Deploy Beacon")
  .addOptionalParam("contract", "Contract implementation name", "TGE")
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

    const beacon = await deploy(`${contract}Beacon`, {
      contract: "UpgradeableBeacon",
      from: deployer,
      args: [implementation.address],
      log: true,
    });

    return beacon;
  });
