import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { deployments, ethers, network } from "hardhat";
import {
    ERC20Mock,
    Pool,
    Service,
    TGE,
    Token,
    Registry,
} from "../typechain-types";
import { CreateArgs, makeCreateData } from "./shared/settings";
import Exceptions from "./shared/exceptions";
import { mineBlock } from "./shared/utils";
import { setup } from "./shared/setup";

const { getContractAt, getContract, getSigners } = ethers;
const { parseUnits } = ethers.utils;

describe("Test Registry", function () {
    let owner: SignerWithAddress,
        donor: SignerWithAddress,
        recipient: SignerWithAddress,
        third: SignerWithAddress;
    let service: Service, registry: Registry;
    let pool: Pool, tge: TGE, token: Token;
    let token1: ERC20Mock;
    let snapshotId: any;
    let createArgs: CreateArgs;

    before(async function () {
        // Get accounts
        [owner, donor, recipient, third] = await getSigners();

        // Fixture
        await deployments.fixture();

        // Get contracts
        service = await getContract("Service");
        registry = await getContract("Registry");
        token1 = await getContract("ONE");

        // Setup
        await setup();

        // Create TGE
        createArgs = await makeCreateData();
        createArgs[3].userWhitelist = [
            owner.address,
            donor.address,
            recipient.address,
            third.address,
        ];

        await service.purchasePool(createArgs[4], createArgs[5], createArgs[2], createArgs[6], {
            value: parseUnits("0.01"),
        });
        const record = await registry.contractRecords(1);

        pool = await getContractAt("Pool", record.addr);


        await service.createPrimaryTGE(pool.address, createArgs[1], createArgs[2], createArgs[2], createArgs[3], createArgs[8]);

        token = await getContractAt("Token", await pool.getGovernanceToken());
        tge = await getContractAt("TGE", await token.tgeList(0));



        // Finalize TGE
        await tge.purchase(parseUnits("1000"), { value: parseUnits("10") });
        await tge
            .connect(donor)
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
    describe("Company Registry", async function () {


        it("Can create company, read and delete company", async function () {
            await registry.createCompany({
                jurisdiction: 1,
                ein: "EIN4",
                dateOfIncorporation: "01.01.2023",
                entityType: 1,
                fee: parseUnits("0.01"),
            });
            expect(await registry.companyAvailable(1, 1)).to.equal(true);
            const companyInfo = await registry.getCompany(1, 1, "EIN4");
            expect(companyInfo.dateOfIncorporation).to.equal("01.01.2023");

            expect(await (await registry.getCompanyDocument(1, 1, "EIN4", 0)).toString()).to.equal("");

            await registry.updateCompanyDocument(1, 1, "EIN4", 0, "ipfs://url3");

            expect(await (await registry.getCompanyDocument(1, 1, "EIN4", 0)).toString()).to.equal("ipfs://url3");

            //Delete companies
            await registry.deleteCompany(1, 1, 1);
            await registry.deleteCompany(1, 1, 0);

            expect(await registry.companyAvailable(1, 1)).to.equal(false);
        });
        expect(await registry.companyAvailable(1, 1)).to.equal(true);
        const companyInfo = await registry.getCompany(1, 1, "EIN4");
        expect(companyInfo.dateOfIncorporation).to.equal("01.01.2023");
    });
    it("Can read count getters", async function () {

        expect(await registry.contractRecordsCount()).to.equal(4);
        expect(await registry.proposalRecordsCount()).to.equal(0);
        expect(await registry.eventRecordsCount()).to.equal(1);
    });

    it("Can update company fee", async function () {
        await registry.createCompany({
            jurisdiction: 1,
            ein: "EIN4",
            dateOfIncorporation: "01.01.2023",
            entityType: 1,
            fee: parseUnits("0.01"),
        });
        await registry.updateCompanyFee(1, 1, 1, parseUnits("0.02"))
        const companyInfo = await registry.getCompany(1, 1, "EIN4");
        expect(companyInfo.fee).to.equal(parseUnits("0.02"));
    });


    it("Can whitelistTokens", async function () {
        await registry.whitelistTokens([token.address]);

        expect(await registry.isTokenWhitelisted(token.address)).to.equal(true);
    });


    it("Can getPoolSecretary", async function () {
        expect(await (await pool.getPoolSecretary()).length).to.equal(0);
    });

    it("Can pause pool", async function () {
        await pool.pause();
        await pool.unpause();
    });

    it("Can pause service", async function () {
        await service.pause();
        await service.unpause();
    });


    it("Can setPoolBeacon", async function () {
        await service.setPoolBeacon(pool.address);
        await expect(service.connect(third).setPoolBeacon(pool.address)).to.be.reverted;
    });

    it("Can setTGEBeacon", async function () {
        await service.setTGEBeacon(tge.address);
        await expect(service.connect(third).setTGEBeacon(tge.address)).to.be.reverted;
    });

    it("Can setTokenBeacon", async function () {
        await service.setTokenBeacon(token.address);
        await expect(service.connect(third).setTokenBeacon(token.address)).to.be.reverted;
    });

    it("Can setVesting", async function () {
        await service.setVesting(token.address);
        await expect(service.connect(third).setVesting(token.address)).to.be.reverted;
    });

    it("Can setCustomProposal", async function () {
        await service.setCustomProposal(token.address);
        await expect(service.connect(third).setCustomProposal(token.address)).to.be.reverted;
    });

    it("Can getMaxHardCap", async function () {
        expect(await (await service.getMaxHardCap(pool.address)).toString()).to.equal("9999000000000000000000");
    });
});