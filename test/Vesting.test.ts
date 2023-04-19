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
    Vesting,
    TGEFactory,
} from "../typechain-types";

import { mineBlock } from "./shared/utils";
import Exceptions from "./shared/exceptions";
import { CreateArgs, makeCreateData } from "./shared/settings";
import { setup } from "./shared/setup";

const { getContract, getContractAt, getSigners } = ethers;
const { parseUnits } = ethers.utils;

describe("Test vesting", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress;
    let service: Service,
        registry: Registry,
        vesting: Vesting,
        tgeFactory: TGEFactory;
    let pool: Pool, tge: TGE, token: Token;
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
        vesting = await getContract("Vesting");
        token1 = await getContract("ONE");
        tgeFactory = await getContract("TGEFactory");

        // Setup
        await setup();

        // First TGE
        createArgs = await makeCreateData();
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

        // Purchase
        await tge
            .connect(other)
            .purchase(parseUnits("1000"), { value: parseUnits("10") });

        // Set claim TVL reached
        await mineBlock(25);
        await vesting.setClaimTVLReached(tge.address);
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

    it("Initial vested info is valid", async function () {
        expect(await vesting.vested(tge.address, other.address)).to.equal(
            parseUnits("500")
        );
        expect(await vesting.totalVested(tge.address)).to.equal(
            parseUnits("500")
        );
        expect(await vesting.claimed(tge.address, other.address)).to.equal(0);
    });

    it("Can't claim before cliff", async function () {
        await mineBlock(10);
        await expect(
            vesting.connect(other).claim(tge.address)
        ).to.be.revertedWith(Exceptions.CLAIM_NOT_AVAILABLE);
    });

    it("After cliff and before first time span only cliff share is available", async function () {
        await mineBlock(100);

        const balanceBefore = await token.balanceOf(other.address);
        expect(await vesting.connect(other).claim(tge.address))
            .to.emit(vesting.address, "Claim")
            .withArgs(tge.address, other.address, parseUnits("50"));
        const balanceAfter = await token.balanceOf(other.address);
        expect(balanceAfter.sub(balanceBefore)).to.equal(parseUnits("50"));
    });

    it("After one span cliff share and one span share are available", async function () {
        await mineBlock(150);

        const balanceBefore = await token.balanceOf(other.address);
        await vesting.connect(other).claim(tge.address);
        const balanceAfter = await token.balanceOf(other.address);
        expect(balanceAfter.sub(balanceBefore)).to.equal(parseUnits("150"));
    });

    it("After two spans cliff share and two span shares are avilable", async function () {
        await mineBlock(200);

        const balanceBefore = await token.balanceOf(other.address);
        await vesting.connect(other).claim(tge.address);
        const balanceAfter = await token.balanceOf(other.address);
        expect(balanceAfter.sub(balanceBefore)).to.equal(parseUnits("250"));
    });

    it("After all vesting period everything is available", async function () {
        await mineBlock(300);

        const balanceBefore = await token.balanceOf(other.address);
        await vesting.connect(other).claim(tge.address);
        const balanceAfter = await token.balanceOf(other.address);
        expect(balanceAfter.sub(balanceBefore)).to.equal(parseUnits("500"));
    });

    it("Can claim in parts", async function () {
        await mineBlock(100);

        let balanceBefore = await token.balanceOf(other.address);
        await vesting.connect(other).claim(tge.address);
        let balanceAfter = await token.balanceOf(other.address);
        expect(balanceAfter.sub(balanceBefore)).to.equal(parseUnits("50"));

        await mineBlock(50);

        balanceBefore = await token.balanceOf(other.address);
        await vesting.connect(other).claim(tge.address);
        balanceAfter = await token.balanceOf(other.address);
        expect(balanceAfter.sub(balanceBefore)).to.equal(parseUnits("100"));
    });

    it("Resolver can cancel vesting for some account (burning remaining tokens)", async function () {
        await mineBlock(100);
        await vesting.connect(other).claim(tge.address);

        expect(await vesting.cancel(tge.address, other.address))
            .to.emit(token.address, "Transfer")
            .withArgs(
                vesting.address,
                ethers.constants.AddressZero,
                parseUnits("450")
            );

        expect(await vesting.vested(tge.address, other.address)).to.equal(
            parseUnits("50")
        );
        expect(await vesting.claimed(tge.address, other.address)).to.equal(
            parseUnits("50")
        );
        expect(await vesting.resolved(tge.address, other.address)).to.equal(
            parseUnits("450")
        );
    });
});
