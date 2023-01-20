import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFunction: DeployFunction = async function ({
    run,
}: HardhatRuntimeEnvironment) {
    await run("deploy:service", {});
};

export default deployFunction;

deployFunction.dependencies = ["Beacons"];

deployFunction.tags = ["Service"];
