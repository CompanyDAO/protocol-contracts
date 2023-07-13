import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { deployments, ethers, network } from "hardhat";

import {
    ERC20Mock,
    Token,
    Pool,
    Service,
    TGE,
    Registry,
    UpgradeableBeacon,
} from "../typechain-types";

import { CreateArgs, makeCreateData } from "./shared/settings";
import { setup } from "./shared/setup";

const { getContract, getSigners } = ethers;

describe("Upgrade beacon test", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress;
    let service: Service, registry: Registry;
    let token1: ERC20Mock;
    let snapshotId: any;
    let createArgs: CreateArgs;

    before(async function () {
        // Get accounts
        [owner, other, third] = await getSigners();

        // Fixture
        await deployments.fixture();

        // Get contracts
        service = await getContract("Service");
        registry = await getContract("Registry");
        token1 = await getContract("ONE");

        // Setup
        await setup();
    });

    beforeEach(async function () {
        snapshotId = await network.provider.request({
            method: "evm_snapshot",
            params: [],
        });

        // Data
        createArgs = await makeCreateData();
    });

    afterEach(async function () {
        snapshotId = await network.provider.request({
            method: "evm_revert",
            params: [snapshotId],
        });
    });

    describe("Uprade tests", function () {
        it("Create company, upgrade beacon and check implementation and pool address", async function () {
           
            // const receipt = await tx.wait();

            // const event = receipt.events!.filter((e) => e.event == "PoolCreated")[0];
            // const pool: Pool = await getContractAt("Pool", event.args![0]);
            // const token: GovernanceToken = await getContractAt(
            //     "GovernanceToken",
            //     event.args![1]
            // );
            // const tge: TGE = await getContractAt("TGE", event.args![2]);

            const poolImplementation = await deployments.deploy(
                "poolImplementation",
                {
                    contract: "Pool",
                    from: owner.address,
                    args: [],
                    log: true,
                }
            );
            const poolBeacon = await getContract<UpgradeableBeacon>(
                "PoolBeacon"
            );
            poolBeacon.upgradeTo(poolImplementation.address);

            // await expect(
            //     service.connect(other).createPool(...createArgs, {
            //         value: parseUnits("0.01"),
            //     })
            // ).to.be.reverted;

            
        });
    });
});
