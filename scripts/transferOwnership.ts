import hre, { ethers, network } from "hardhat";
import { Service, Directory } from "../typechain-types";

function sleep(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
    console.log("Transferring Service...");

    const service = await ethers.getContract<Service>("Service");
    await service.transferOwnership(process.env.OWNER!).then((tx) => tx.wait());

    console.log("Transferring Directory...");

    const directory = await ethers.getContract<Directory>("Directory");
    await directory
        .transferOwnership(process.env.OWNER!)
        .then((tx) => tx.wait());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
