import { task } from "hardhat/config";
import { Registry, CustomProposal } from "../../typechain-types";

task("deploy:service", "Deploy Service").setAction(async function (
    { _ },
    { getNamedAccounts, deployments: { deploy }, ethers: { getContract } }
) {
    // Create deploy function
    const { deployer } = await getNamedAccounts();
    const deployProxy = async (name: string, args: any[]) => {
        return await deploy(name, {
            from: deployer,
            args: [],
            log: true,
            proxy: {
                proxyContract: "OpenZeppelinTransparentProxy",
                execute: {
                    init: {
                        methodName: "initialize",
                        args: args,
                    },
                },
            },
        });
    };

    // Deploy Registry
    const registry = await deployProxy("Registry", []);

    //Deploy customProposal
    const customProposal = await deployProxy("CustomProposal", []);

    // Deploy Vesting
    const vesting = await deployProxy("Vesting", [registry.address]);


    // Get Beacons
    const poolBeacon = await getContract("PoolBeacon");
    const tokenBeacon = await getContract("TokenBeacon");
    const tgeBeacon = await getContract("TGEBeacon");

    // Deploy Service
    const service = await deployProxy("Service", [
        registry.address,
        customProposal.address,
        vesting.address,
        poolBeacon.address,
        tokenBeacon.address,
        tgeBeacon.address,
        10000, // 1%
    ]);

    // Set Service in Registry
    const registryContract = await getContract<Registry>("Registry");
    await registryContract.setService(service.address);

    // Set Service in Registry
    const customProposalContract = await getContract<CustomProposal>(
        "CustomProposal"
    );
    await customProposalContract.setService(service.address);

    return service;
});
