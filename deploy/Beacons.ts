import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployFunction: DeployFunction = async function ({
    run,
}: HardhatRuntimeEnvironment) {
    await run("deploy:beacon", { contract: "Pool" });
    await run("deploy:beacon", { contract: "Token" });
    await run("deploy:beacon", { contract: "TokenERC1155" });
    await run("deploy:beacon", { contract: "TGE" });
    await run("deploy:beacon", { contract: "TSE" });
};

export default deployFunction;

deployFunction.tags = ["Beacons"];
