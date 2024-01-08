import { task, types } from 'hardhat/config';

task("deploy:update", "Deploy Proxy")
    .setAction(async function (
        { _ },
        { getNamedAccounts, deployments: { deploy }, ethers: { getContract } }

    ) {
        const registry = "0x82d24e8CEFd6D10aB99f3a4F30D8A87aF1A61a88"
        const service = "0x5860B6a91f7Af98f80A2510E287d5422fd43159E"
        const owner = "0xD076441BEA2EbB30feE945C042AAbc34b1C937e6" //safe_address
        const realProxyAdminAddress = "0x806eE81d833F5cF71B0506685AB28715bA63367a"

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
        let proxy: any;

 
        //registry: 0x82d24e8CEFd6D10aB99f3a4F30D8A87aF1A61a88
        //service: 0x5860B6a91f7Af98f80A2510E287d5422fd43159E


        

        let implementation:any;
        let beacon:any;
        const beacons:any = []
        let contractName
        for(let i = 0; i < beacons.length; i++) {
            contractName = beacons[i]   
            await sleep(20000);
            implementation = await deploy(`${contractName}Implementation`, {
                contract: contractName,
                from: deployer,
                args: [],
                log: true,
            });
        
            beacon = await deploy(`${contractName}Beacon`, {
                contract: "UpgradeableBeacon",
                from: deployer,
                args: [implementation.address],
                log: true,
            });
            console.log(contractName," Beacon\t|", beacon.address);
            beacon = await getContract(
                `${contractName}Beacon`
                 );
            try{
                await beacon.transferOwnership(owner);
            }catch{

            }
            console.log(contractName," Beacon transferOwnership\t| Done");
            
        }

        const implementationss = ['Pool','Registry', 'Invoice']
        for(let i = 0; i < implementationss.length; i++) {
            contractName = implementationss[i]
            await sleep(20000);
            implementation = await deploy(`${contractName}Implementation`, {
                contract: contractName,
                from: deployer,
                args: [],
                log: true,
            });
          
            console.log(contractName," implementation\t|",implementation.address);
            
        }
        
        console.log("Sleeping before verification...");

        await sleep(20000);


        return proxy;
    });
    function sleep(ms: number) {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }