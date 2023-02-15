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
} from "../typechain-types";
import Exceptions from "./shared/exceptions";
import {
    CreateArgs,
    makeCreateData,
    TGEArgs,
    makeTGEArgs,
} from "./shared/settings";
import { mineBlock } from "./shared/utils";
import { setup } from "./shared/setup";

const { getContractAt, getContract, getSigners, provider } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

describe("Test Registry", function () {
    let owner: SignerWithAddress,
        donor: SignerWithAddress,
        recipient: SignerWithAddress,
        third: SignerWithAddress,
        fourth: SignerWithAddress;
    let service: Service, registry: Registry;
    let pool: Pool, tge: TGE, token: Token;
    let token1: ERC20Mock;
    let snapshotId: any;
    let createArgs: CreateArgs;
    let tgeArgs: TGEArgs;
    let tx: ContractTransaction;

    before(async function () {
        // Get accounts
        [owner, donor,recipient, third, fourth] = await getSigners();

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
            third.address
        ];
        await service.createPool(...createArgs, {
            value: parseUnits("0.01"),
        });
        const record = await registry.contractRecords(0);
        pool = await getContractAt("Pool", record.addr);
        token = await getContractAt("Token", await pool.tokens(1));
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
        

        it("Can create company and read company info", async function () {
            await registry.createCompany({
                jurisdiction: 1,
                ein: "EIN4",
                dateOfIncorporation: "01.01.2023",
                entityType: 1,
                fee: parseUnits("0.01"),
            });
            expect(await registry.companyAvailable(1,1)).to.equal(true);
            const companyInfo = await registry.getCompany(1,1,"EIN4");
           expect(companyInfo.dateOfIncorporation).to.equal("01.01.2023");

        });

        it("Can update company fee", async function () {
           await registry.createCompany({
                jurisdiction: 1,
                ein: "EIN4",
                dateOfIncorporation: "01.01.2023",
                entityType: 1,
                fee: parseUnits("0.01"),
            });
            await registry.updateCompanyFee(1,1,1, parseUnits("0.02"))
           const companyInfo = await registry.getCompany(1,1,"EIN4");
           expect(companyInfo.fee).to.equal(parseUnits("0.02"));
        });
        
    });
});