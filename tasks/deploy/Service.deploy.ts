import { task } from "hardhat/config";
import { Registry, CustomProposal, Service } from "../../typechain-types";

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
    const customProposal = await deployProxy("CustomProposal", [registry.address]);

    //Deploy IDRegistry
    const IDRegistry = await deployProxy("IDRegistry", [registry.address]);

    //Deploy Invoice
    const invoice = await deployProxy("Invoice", [registry.address]);

    // Deploy Vesting
    const vesting = await deployProxy("Vesting", [registry.address]);

    // Get Beacons
    const poolBeacon = await getContract("PoolBeacon");
    const tokenBeacon = await getContract("TokenBeacon");
    const tokenERC1155Beacon = await getContract("TokenERC1155Beacon");
    const tgeBeacon = await getContract("TGEBeacon");
    const tseBeacon = await getContract("TSEBeacon");

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

    // Deploy factories
    const tokenFactory = await deployProxy("TokenFactory", [service.address]);
    const tgeFactory = await deployProxy("TGEFactory", [service.address]);

    // Set factories in Service
    const serviceContract = await getContract<Service>("Service");
    await serviceContract.setFactories(
        tokenFactory.address,
        tgeFactory.address
    );
    
    await serviceContract.setInvoice(
        invoice.address
    );

    await serviceContract.setIdRegistry(
        IDRegistry.address
    );

    await serviceContract.setTokenERC1155Beacon(
        tokenERC1155Beacon.address
    );

    await serviceContract.setTrustForwarder(
        "0xE7e5605aC99ED54Ff6E6e32c52e9Ed91AA0163bC"
    );

    // Set Service in Registry
    const registryContract = await getContract<Registry>("Registry");
    await registryContract.setService(service.address);

    await serviceContract.setTSEBeacon(
        tseBeacon.address
    );

    await serviceContract.setInvoice(
        invoice.address
    );
    let safe_address = process.env.SAFE || deployer;
    await serviceContract.grantRole(
        await serviceContract.DEFAULT_ADMIN_ROLE(),
        safe_address
    );

    await registryContract.grantRole(
        await registryContract.DEFAULT_ADMIN_ROLE(),
        safe_address
    );
    
    return service;
});
