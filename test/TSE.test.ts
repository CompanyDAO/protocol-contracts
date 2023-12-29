import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, ContractTransaction } from "ethers";
import { deployments, ethers, network } from "hardhat";
import {
    ERC20Mock,
    Pool,
    Service,
    TGE,
    Token,
    Registry,
    CustomProposal,
    Vesting,
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

const { getContractAt, getContract, getSigners } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

describe("Test secondary TSE", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        second: SignerWithAddress,
        third: SignerWithAddress,
        fourth: SignerWithAddress;
    let service: Service,
        registry: Registry,
        vesting: Vesting,
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
        vesting = await getContract("Vesting");
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

    describe("TSE for governance token", async function () {
        this.beforeEach(async function () {
            // Propose secondary TGE

            tgeArgs = await makeTGEArgs(token.address, createArgs[3]);
            await mineBlock(5);
            tx = await customProposal.proposeTGE(pool.address, ...tgeArgs);
        });

      

        it("Can create TSE", async function () {
            
            await mineBlock(100);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(true);

            let amount = (await token.unlockedBalanceOf(owner.address)).div(2)

            await token.approve(tgeFactory.address,amount)

            await tgeFactory.createTSE(
                token.address,
                0,
                {
                    amount: amount,
                    unitOfAccount: AddressZero,
                    price: 100,
                    minPurchase: 0,
                    maxPurchase: amount,
                    duration: 20,
                    userWhitelist: [owner.address, other.address],
                },
                "",
                owner.address
              );

            let tseAddress = await token.tseList(owner.address,0)
            let tse = await getContractAt("TSE", tseAddress);


            await tse.connect(other).purchase(amount.div(2), { value: parseUnits("1")});

            // console.log((await token.balanceOf(tseAddress)).toString());
            // console.log((await token.balanceOf(owner.address)).toString());
            // console.log(tseAddress)
           
            await tse.finishTSE();

            // console.log((await token.balanceOf(tseAddress)).toString());
            // console.log((await token.balanceOf(owner.address)).toString());

        });

        



    });
});
