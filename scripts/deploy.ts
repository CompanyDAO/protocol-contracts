import hre, { ethers, network } from "hardhat";

function sleep(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
    const args: [] = [];

    const ContractFactory = await ethers.getContractFactory("Contract");
    const contract = await ContractFactory.deploy(...args);
    await contract.deployed();

    console.log("Contract deployed to:", contract.address);

    if (network.name !== "localhost" && network.name !== "hardhat") {
        console.log("Sleeping before verification...");
        await sleep(20000);

        await hre.run("verify:verify", {
            address: contract.address,
            constructorArgs: args,
        });
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
