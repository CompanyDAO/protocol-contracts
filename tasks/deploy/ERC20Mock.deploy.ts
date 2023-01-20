import { task } from "hardhat/config";

task("deploy:erc20Mock", "Deploy ERC20Mock").setAction(async function (
    { name, symbol },
    { getNamedAccounts, deployments: { deploy } }
) {
    const { deployer } = await getNamedAccounts();

    return await deploy(symbol, {
        contract: "ERC20Mock",
        from: deployer,
        args: [name, symbol],
        log: true,
    });
});
