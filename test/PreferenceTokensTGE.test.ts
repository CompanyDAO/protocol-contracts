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

describe("Test TGE for Preference Tokens", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        second: SignerWithAddress,
        third: SignerWithAddress,
        fourth: SignerWithAddress;
    let service: Service,
        registry: Registry,
        customProposal: CustomProposal,
        tgeFactory: TGEFactory;
    let pool: Pool, tge: TGE, token: Token;
    let token1: ERC20Mock;
    let snapshotId: any;
    let createArgs: CreateArgs;
    let tgeArgs: TGEArgs;
    let tx: ContractTransaction;

    before(async function () {
        // Get accounts
        [owner, other, second, third, fourth] = await getSigners();

        // Fixture
        await deployments.fixture();

        // Get contracts
        service = await getContract("Service");
        registry = await getContract("Registry");
        token1 = await getContract("ONE");
        customProposal = await getContract("CustomProposal");
        tgeFactory = await getContract("TGEFactory");

        // Setup
        await setup();

        // Create TGE
        createArgs = await makeCreateData();
        createArgs[3].userWhitelist = [
            owner.address,
            other.address,
            second.address,
            third.address,
        ];
        
        createArgs[3].userWhitelistMin = [0,0,0,0];
        createArgs[3].userWhitelistMax = [0,0,0,0];
        await service.purchasePool(
            createArgs[4],
            createArgs[5],
            createArgs[2],
            createArgs[6],
            {
                value: parseUnits("0.01"),
            }
        );
        const record = await registry.contractRecords(1);

        pool = await getContractAt("Pool", record.addr);

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

    describe("TGE for preference token", async function () {
        let pToken: Token, pTGE: TGE;

        this.beforeEach(async function () {
            // Propose secondary TGE
            tgeArgs = await makeTGEArgs(AddressZero, createArgs[3], {
                tokenType: 2,
                name: "Preference DAO",
                symbol: "PDAO",
                cap: parseUnits("10000", 6),
                decimals: 6,
                description: "This is a preference token",
            });
            tgeArgs[1].minPurchase = 1;
            tgeArgs[1].maxPurchase = parseUnits("3000", 6);
            tgeArgs[1].hardcap = parseUnits("5000", 6);
            tgeArgs[1].softcap = parseUnits("1000", 6);

           

            tx = await customProposal.proposeTGE(pool.address, ...tgeArgs);

            //waiting for voting start
            await mineBlock(10);

            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);
            await mineBlock(2);
            await pool.executeProposal(1);

            const tgeRecord = await registry.contractRecords(4);
            pTGE = await getContractAt("TGE", tgeRecord.addr);
            pToken = await getContractAt("Token", await pTGE.token());
        });

        it("Can participate in TGE for preference", async function () {
            
            await pTGE.purchase(parseUnits("100", 6), {
                value: parseUnits("1"),
            });
            expect(await pToken.balanceOf(owner.address)).to.equal(
                parseUnits("50", 6)
            );
        });

        it("If bought less than softcap TGE is failed", async function () {
            await pTGE.purchase(parseUnits("100", 6), {
                value: parseUnits("1"),
            });
            await mineBlock(100);
            expect(await pTGE.state()).to.equal(1);
        });

        it("External Purchase works", async function () {

            await pTGE.externalPurchase(second.address,parseUnits("100", 6));

            expect(await pToken.balanceOf(second.address)).to.equal(
                parseUnits("50", 6)
            );
        });


        it("Can't start TGE if Active TGE exists", async function () {
            // Start new TGE
            tgeArgs = await makeTGEArgs(await pTGE.token(), createArgs[3], {
                tokenType: 2,
                name: "Preference DAO UPD",
                symbol: "PDAOUPD",
                cap: parseUnits("10000"),
                decimals: 10,
                description: "Another description",
            });
            tx = await customProposal.proposeTGE(pool.address, ...tgeArgs);
            //waiting for voting start
            await mineBlock(10);
            await pool.connect(owner).castVote(2, true);
            await pool.connect(other).castVote(2, true);
            await mineBlock(2);
            expect(await pTGE.state()).to.equal(0);
            await expect(pool.executeProposal(2)).to.be.revertedWith(
                Exceptions.ACTIVE_TGE_EXISTS
            );
        });

        it("After preference initial TGE is successful, following TGE's can't update token data", async function () {
            // Success first TGE
            await pTGE.purchase(parseUnits("1000", 6), {
                value: parseUnits("10"),
            });
            await mineBlock(100);
            expect(await pTGE.state()).to.equal(2);

            // Start new TGE
            tgeArgs = await makeTGEArgs(await pTGE.token(), createArgs[3], {
                tokenType: 2,
                name: "Preference DAO UPD",
                symbol: "PDAOUPD",
                cap: parseUnits("10000"),
                decimals: 10,
                description: "Another description",
            });
            tx = await customProposal.proposeTGE(pool.address, ...tgeArgs);
            //waiting for voting start
            await mineBlock(10);
            await pool.connect(owner).castVote(2, true);
            await pool.connect(other).castVote(2, true);
            await mineBlock(2);
            await pool.executeProposal(2);

            // Check values
            expect(await pToken.name()).to.equal("Preference DAO");
            expect(await pToken.symbol()).to.equal("PDAO");
            expect(await pToken.decimals()).to.equal(6);
            expect(await pToken.description()).to.equal(
                "This is a preference token"
            );
        });

        it("Can create several Preference Tokens TGE", async function () {
            // Success first TGE
            await pTGE.purchase(parseUnits("1000", 6), {
                value: parseUnits("10"),
            });
            await mineBlock(100);
            expect(await pTGE.state()).to.equal(2);

            // Start new TGE
            tgeArgs = await makeTGEArgs(AddressZero, createArgs[3], {
                tokenType: 2,
                name: "Preference DAO UPD Second",
                symbol: "PDAOUPD2",
                cap: parseUnits("10000"),
                decimals: 10,
                description: "Another description",
            });
            tx = await customProposal.proposeTGE(pool.address, ...tgeArgs);
            //waiting for voting start
            await mineBlock(10);
            await pool.connect(owner).castVote(2, true);
            await pool.connect(other).castVote(2, true);
            await mineBlock(2);
            await pool.executeProposal(2);

            let preferenceTokens = await pool.getTokens(2);

            expect(preferenceTokens.length).to.equal(2);

            let pTokenSecond = await getContractAt(
                "Token",
                preferenceTokens[1]
            );

            // Check values
            expect(await pTokenSecond.name()).to.equal(
                "Preference DAO UPD Second"
            );
            expect(await pTokenSecond.symbol()).to.equal("PDAOUPD2");
        });
    });
});
