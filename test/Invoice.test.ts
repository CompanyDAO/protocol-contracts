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
    Invoice,
    CustomProposal,
    TGEFactory,
} from "../typechain-types";

import { InvoiceCoreStruct } from "../typechain-types/Invoice";
import Exceptions from "./shared/exceptions";
import { CreateArgs, makeCreateData } from "./shared/settings";
import { mineBlock } from "./shared/utils";
import { setup } from "./shared/setup";

const { getContractAt, getContract, getSigners, provider } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

describe("Test Invoice", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress,
        fourth: SignerWithAddress;
    let service: Service,
        Registry: Registry,
        customProposal: CustomProposal,
        invoice: Invoice,
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
        invoice = await getContract("Invoice");
        tgeFactory = await getContract("TGEFactory");
        // Setup
        await setup();

        // Create TGE
        createArgs = await makeCreateData();
        createArgs[3].userWhitelist = [owner.address, other.address, third.address];
        createArgs[3].userWhitelistMin = [0,0,0];
        createArgs[3].userWhitelistMax = [0,0,0];
        await service.purchasePool(createArgs[4], createArgs[5], createArgs[2], createArgs[6], {
            value: parseUnits("0.01"),
        });
        const record = await Registry.contractRecords(1);

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

    describe("Create invoice ETH", function () {
        this.beforeEach(async function () {

            await service.grantRole(
                await service.SERVICE_MANAGER_ROLE(),
                owner.address
            );
            await mineBlock(1);

            let invoiceCore: InvoiceCoreStruct = {
                amount: parseUnits("0.01"),
                unitOfAccount: AddressZero,
                expirationBlock: 100,
                description: "descr",
                whitelist: [owner.address]
            };
            tx = await invoice
                .createInvoice(
                    pool.address,
                    invoiceCore
                );
            await invoice
                .createInvoice(
                    pool.address,
                    invoiceCore
                );
        });


        it("Can get invoice info ", async function () {

            expect(
                await invoice.invoiceState(pool.address, 0)
            ).to.equal(1);

            expect(
                await (await invoice.invoices(pool.address, 0)).core.amount
            ).to.equal(parseUnits("0.01"));

            expect(
                await invoice.eventIndex(pool.address, 1)
            ).to.equal(2);

        });

        it("Can pay invoice", async function () {
            await expect(invoice.connect(third).payInvoice(pool.address, 0)).to.be.revertedWith(
                Exceptions.NOT_WHITELISTED
            );
            await invoice.payInvoice(pool.address, 0, { value: parseUnits("0.01") });
            await expect(invoice.payInvoice(pool.address, 0)).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
            expect(
                await invoice.invoiceState(pool.address, 0)
            ).to.equal(2);

            await mineBlock(121);
            await expect(invoice.payInvoice(pool.address, 1)).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Can cancel invoice", async function () {
            await invoice.cancelInvoice(pool.address, 0);
            expect(
                await invoice.invoiceState(pool.address, 0)
            ).to.equal(4);
        });

        it("Can't pay expired invoice", async function () {
            expect(
                await invoice.invoiceState(pool.address, 0)
            ).to.equal(1);
            await mineBlock(120);
            expect(
                await invoice.invoiceState(pool.address, 0)
            ).to.equal(3);
            await expect(invoice.payInvoice(pool.address, 0)).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Service manager can set invoicePaid", async function () {
            expect(
                await invoice.invoiceState(pool.address, 0)
            ).to.equal(1);

            await invoice.setInvoicePaid(pool.address, 0)

            expect(
                await invoice.invoiceState(pool.address, 0)
            ).to.equal(2);
            await mineBlock(120);

        });

    });

});
