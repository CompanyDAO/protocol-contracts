import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ContractTransaction } from "ethers";
import { deployments, ethers, network } from "hardhat";
import {
    ERC20Mock,
    Pool,
    Service,
    TGE,
    Token,
    Registry,
    CustomProposal,
    TGEFactory,
} from "../typechain-types";
import Exceptions from "./shared/exceptions";
import { CreateArgs, makeCreateData } from "./shared/settings";
import { mineBlock } from "./shared/utils";
import { setup } from "./shared/setup";

const { getContractAt, getContract, getSigners, provider } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

describe("Test custom proposals", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress,
        fourth: SignerWithAddress;
    let service: Service,
        Registry: Registry,
        customProposal: CustomProposal,
        tgeFactory: TGEFactory;
    let pool: Pool, tge: TGE, token: Token;
    let token1: ERC20Mock;
    let snapshotId: any;
    let createArgs: CreateArgs;
    let tx: ContractTransaction;

    before(async function () {
        // Get accounts
        [owner, other, third, fourth] = await getSigners();

        // Fixture
        await deployments.fixture();

        // Get contracts
        service = await getContract("Service");
        Registry = await getContract("Registry");
        token1 = await getContract("ONE");
        customProposal = await getContract("CustomProposal");
        tgeFactory = await getContract("TGEFactory");
        // Setup
        await setup();

        // Create TGE
        createArgs = await makeCreateData();
        createArgs[3].userWhitelist = [owner.address, other.address, third.address];
        createArgs[3].userWhitelistMin = [0,0,0];
        createArgs[3].userWhitelistMax = [0,0,0];
        await service.purchasePool(
            createArgs[4],
            createArgs[5],
            createArgs[2],
            createArgs[6],
            {
                value: parseUnits("0.01"),
            }
        );
        const record = await Registry.contractRecords(1);

        pool = await getContractAt("Pool", record.addr);
        
        const newCompanyAddress = await Registry.getAvailableCompanyAddress(1,1);

        await tgeFactory.createPrimaryTGE(
            pool.address,
            {
                tokenType: 1,
                cap: createArgs[1],
                name: createArgs[2],
                symbol: createArgs[2],
                description: "",
                decimals: 18,
            },
            createArgs[3],
            createArgs[8],
            createArgs[6],
            [owner.address],
            [owner.address]
        );

        token = await getContractAt("Token", await pool.getGovernanceToken());
        
        tge = await getContractAt("TGE", await token.tgeList(0));

        

        // Finalize TGE
        await tge.purchase(parseUnits("1000"), { value: parseUnits("10") });
        await tge
            .connect(other)
            .purchase(parseUnits("1000"), { value: parseUnits("10") });
        await tge
            .connect(third)
            .purchase(parseUnits("1000"), { value: parseUnits("10") });
        await mineBlock(20);
    });

    beforeEach(async function () {
        snapshotId = await network.provider.request({
            method: "evm_snapshot",
            params: [],
        });
    });

    afterEach(async function () {
        snapshotId = await network.provider.request({
            method: "evm_revert",
            params: [snapshotId],
        });
    });

    describe("Transfer ETH", function () {

        


        this.beforeEach(async function () {

            tx = await customProposal
                .connect(other)
                .proposeTransfer(
                    pool.address,
                    AddressZero,
                    [third.address, fourth.address],
                    [parseUnits("0.1"), parseUnits("0.1")],
                    "Let's give them money",
                    "#"
                );
        });

        it("Getting/Setting GlobalProposalId works", async function () {
            // console.log(await customProposal.getTrustedForwarder());
            await customProposal
                .connect(other)
                .proposeTransfer(
                    pool.address,
                    AddressZero,
                    [third.address, fourth.address],
                    [parseUnits("0.1"), parseUnits("0.1")],
                    "Let's give them money",
                    "#"
                );
            
            expect(await Registry.getGlobalProposalId(pool.address, 1)).to.equal(0);
            expect(await Registry.getGlobalProposalId(pool.address, 2)).to.equal(1);
        });

        it("Executing succeeded transfer proposals should work", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);
            await mineBlock(2);
            await owner.sendTransaction({
                to: pool.address,
                value: parseUnits("10"),
            });

            const thirdBefore = await provider.getBalance(third.address);
            const fourthBefore = await provider.getBalance(fourth.address);
            await pool.executeProposal(1);
            const thirdAfter = await provider.getBalance(third.address);
            const fourthAfter = await provider.getBalance(fourth.address);
            expect(await provider.getBalance(pool.address)).to.equal(
                parseUnits("9.8")
            );
            expect(thirdAfter.sub(thirdBefore)).to.equal(parseUnits("0.1"));
            expect(fourthAfter.sub(fourthBefore)).to.equal(parseUnits("0.1"));
        });
    });
});
