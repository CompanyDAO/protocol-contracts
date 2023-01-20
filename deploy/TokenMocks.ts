import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFunction: DeployFunction = async function ({
    run,
}: HardhatRuntimeEnvironment) {
    await run("deploy:erc20Mock", { name: "Token 1", symbol: "ONE" });

    await run("deploy:erc20Mock", { name: "Token 2", symbol: "TWO" });

    await run("deploy:erc20Mock", { name: "Token 3", symbol: "THREE" });
};

export default deployFunction;

deployFunction.tags = ["TokenMocks"];
