import { task, types } from 'hardhat/config';

task("deploy:proxy", "Deploy Proxy")
    .addParam(
        'contract',
        'The name of new upgradeable contract',
        undefined,
        types.string
    )
    .setAction(async function (
        { contract },
        { getNamedAccounts, deployments: { deploy } }
    ) {
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
      
        const proxy = await deployProxy(contract, []);
     
        console.log("Contract deployed to:", proxy.address);
        return proxy;
    });
