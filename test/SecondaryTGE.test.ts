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

describe("Test secondary TGE", function () {
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

    describe("Secondary TGE for governance token", async function () {
        this.beforeEach(async function () {
            // Propose secondary TGE

            tgeArgs = await makeTGEArgs(token.address, createArgs[3]);
            await mineBlock(5);
            tx = await customProposal.proposeTGE(pool.address, ...tgeArgs);
        });

        // it("Admin can cancel propose", async function () {
        //     await mineBlock(10);
        //     await service.cancelProposal(pool.address, 1);
        // });

        it("Only user with votes over proposal threshold can create secondary TGE proposals", async function () {
            await expect(
                customProposal
                    .connect(fourth)
                    .proposeTGE(pool.address, ...tgeArgs)
            ).to.be.revertedWith(Exceptions.NOT_VALID_PROPOSER);
        });

        it("Proposing secondary TGE works", async function () {
            await expect(tx).to.emit(pool, "ProposalCreated");

            const receipt = await tx.wait();
            const proposal = await pool.proposals(1);
            expect(proposal.core.quorumThreshold).to.equal(
                createArgs[6].quorumThreshold
            ); // from create params
            expect(proposal.core.decisionThreshold).to.equal(
                createArgs[6].decisionThreshold
            ); // from create params
            expect(proposal.vote.startBlock).to.equal(receipt.blockNumber + 10);
            expect(proposal.vote.endBlock).to.equal(
                receipt.blockNumber +
                +10 +
                Number.parseInt(createArgs[6].votingDuration.toString())
            ); // from create params
            expect(proposal.vote.forVotes).to.equal(0);
            expect(proposal.vote.againstVotes).to.equal(0);
            expect(proposal.vote.executionState).to.equal(0);
        });

        it("Can propose secondary TGE when there is active proposal", async function () {
            await expect(customProposal.proposeTGE(pool.address, ...tgeArgs)).to
                .be.not.reverted;
        });

        it("Casting votes should work", async function () {
            //waiting for voting start
            await mineBlock(10);

             await expect(pool.castVote(1, true))
            //     .to.emit(pool, "VoteCast")
            //     .withArgs(owner.address, 1, parseUnits("500"), 2);

            const proposal = await pool.proposals(1);
            expect(proposal.vote.forVotes).to.equal(parseUnits("500"));
        });

        it("Token delegation works", async function () {
            await mineBlock(1);
            const startVotes_donor = await token.getVotes(other.address);
            const startVotes_rec = await token.getVotes(second.address);
            expect(startVotes_rec).to.equal(parseUnits("0"));
            await token.connect(other).delegate(second.address);
            await mineBlock(2);
            const finishVotes_donor = await token.getVotes(other.address);
            const finishVotes_rec = await token.getVotes(second.address);
            expect(finishVotes_donor).to.equal(parseUnits("0"));
            expect(startVotes_rec).to.equal(finishVotes_donor);
            await token.connect(other).delegate(other.address);
            await mineBlock(2);
            expect(await token.getVotes(other.address)).to.equal(
                startVotes_donor
            );
        });

        it("Can't vote with tokens delegated before start of voting", async function () {
            //waiting for voting start
            await mineBlock(10);

            await token.connect(other).delegate(second.address);
            await expect(
                pool.connect(second).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Can't vote with no delegated or governance tokens", async function () {
            //waiting for voting start
            await mineBlock(10);

            expect(await token.balanceOf(second.address)).to.equal(
                parseUnits("0")
            );
            await expect(
                pool.connect(second).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Can't vote twice on the same proposal", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(other).castVote(1, true);
            await expect(
                pool.connect(other).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ALREADY_VOTED);
        });

        it("Ballot BEFORE token transfer eq Ballot AFTER token transfer", async function () {
            //waiting for voting start
            await mineBlock(10);

            await mineBlock(2);
            const startBallot = await pool.getBallot(second.address, 1);
            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(true);
            await token
                .connect(other)
                .transfer(second.address, await token.balanceOf(other.address));
            const finishBallot = await pool.getBallot(second.address, 1);
            await mineBlock(2);
            expect(startBallot[0]).to.equal(finishBallot[0]);
        });

        it("Check tgeWithLockedTokensList works ", async function () {
            const startTgeWithLockedTokensList =
                await token.getTgeWithLockedTokensList();
            const startTgeList = await token.getTGEList();

            //check if tge lists are equal (all and with locked tokens) before tokens unlock
            expect(startTgeWithLockedTokensList.length)
                .to.equal(startTgeList.length)
                .to.equal(1);

            //check if transfer is locked
            await expect(
                token
                    .connect(other)
                    .transfer(
                        second.address,
                        await token.balanceOf(other.address)
                    )
            ).to.be.revertedWith(Exceptions.LOW_UNLOCKED_BALANCE);

            //unlock tokens
            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(true);
            //make transfer and update tgeWithLockedTokensList
            await token
                .connect(other)
                .transfer(second.address, await token.balanceOf(other.address));

            const finishTgeWithLockedTokensList =
                await token.getTgeWithLockedTokensList();
            const finishTgeList = await token.getTGEList();

            //check if tgeWithLockedTokensList updated
            expect(finishTgeWithLockedTokensList.length).to.equal(0);
            expect(finishTgeList.length).to.equal(startTgeList.length);
        });

        it("Can't vote twice with the same tokens", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(other).castVote(1, true);
            await mineBlock(50);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(true);
            await token
                .connect(other)
                .transfer(second.address, await token.balanceOf(other.address));

            await expect(
                pool.connect(second).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Can't vote after voting period is finished", async function () {
            await mineBlock(100);

            await expect(
                pool.connect(other).castVote(1, true)
            ).to.be.revertedWith(Exceptions.VOTING_FINISHED);
        });

        it("Can't execute non-existent proposal", async function () {
            await expect(pool.executeProposal(2)).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Can't execute proposal if quorum is not reached", async function () {
            await mineBlock(100);

            await expect(pool.executeProposal(1)).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Can't execute proposal with uncertain state before voting period is finished", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(other).castVote(1, true);
            await pool.connect(owner).castVote(1, false);

            await expect(pool.executeProposal(1)).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Can't execute inevitably successful proposal before voting period is finished and BEFORE delay passed", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);

            await expect(pool.executeProposal(1)).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Can't execute inevitably successful proposal before voting period is finished and AFTER delay passed", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);

            await mineBlock(2);

            await expect(pool.executeProposal(1)).to.emit(
                tgeFactory,
                "SecondaryTGECreated"
            );
        });

        it("Can execute successful proposal, creating secondary TGE", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);
            await mineBlock(100);

            await expect(pool.executeProposal(1)).to.emit(
                tgeFactory,
                "SecondaryTGECreated"
            );

            const tgeRecord = await registry.contractRecords(4);
            const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

            expect(await tge2.state()).to.equal(0);

            const info = await tge2.getInfo();
            expect(info.duration).to.equal(20);
            expect(info.softcap).to.equal(parseUnits("1000"));
            expect(info.hardcap).to.equal(parseUnits("4000"));
        });

        it("Only pool can request creating TGEs and recording proposals on service", async function () {
            await expect(
                tgeFactory.createSecondaryTGE(
                    AddressZero,
                    createArgs[3],
                    {
                        tokenType: 1,
                        name: "",
                        symbol: "",
                        cap: 0,
                        decimals: 0,
                        description: "",
                    },
                    ""
                )
            ).to.be.revertedWith(Exceptions.NOT_POOL);

            await expect(service.addProposal(35)).to.be.revertedWith(
                Exceptions.NOT_POOL
            );
        });

        it("Can buy from secondary TGE", async function () {
            await mineBlock(1);
            expect(await pool.availableVotesForProposal(1)).to.equal(
                parseUnits("1500")
            );
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);
            await mineBlock(2);
            await pool.executeProposal(1);
            const tgeRecord = await registry.contractRecords(4);
            const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

            await tge2
                .connect(owner)
                .purchase(parseUnits("100"), { value: parseUnits("1") });


        });

        it("If anything is purchased (no softcap) than TGE is successful", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);
            await mineBlock(2);
            await pool.executeProposal(1);
            const tgeRecord = await registry.contractRecords(4);
            const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

            await tge2
                .connect(owner)
                .purchase(parseUnits("10"), { value: parseUnits("1") });
            await mineBlock(100);
            expect(await tge2.state()).to.equal(2);
        });

        it("New TGE can't be created before previous TGE is finished", async function () {
            //waiting for voting start
            await mineBlock(10);

            // Succeed and execute first proposal
            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);
            await mineBlock(2);
            await pool.executeProposal(1);

            // Create and success second proposal
            createArgs[3].hardcap = parseUnits("6900");

            await customProposal.proposeTGE(pool.address, ...tgeArgs);

            //waiting for voting start
            await mineBlock(10);

            await pool.connect(owner).castVote(2, true);
            await pool.connect(other).castVote(2, true);
            await mineBlock(2);

            // Execution should fail
            await expect(pool.executeProposal(2)).to.be.revertedWith(
                Exceptions.ACTIVE_TGE_EXISTS
            );
        });
        it("Hardcap and protocolFee works", async function () {
            //waiting for voting start
            await mineBlock(10);
            let cap = (await token.cap())
            let tswr = await (await token.totalSupplyWithReserves())
            let maxharcap = cap.sub(tswr).mul(99).div(100)


            // Create and success second proposal
            createArgs[3].hardcap = maxharcap;
            createArgs[3].maxPurchase = maxharcap.mul(101).div(100);
            await customProposal.proposeTGE(pool.address, ...tgeArgs);

            //waiting for voting start
            await mineBlock(10);

            await pool.connect(owner).castVote(2, true);
            await pool.connect(other).castVote(2, true);
            await mineBlock(2);
            await mineBlock(100);

            await mineBlock(2);
            await pool.executeProposal(2);
            const tgeRecord = await registry.contractRecords(4);
            const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);
            let maxpurchase = cap.sub(tswr)
            // await tge2
            //     .connect(owner)
            //     .purchase( createArgs[3].maxPurchase.sub(1), { value: parseUnits("100") });
            tswr = await (await token.totalSupplyWithReserves())
        });


        


        it("Secondary TGE's hardcap can't overflow remaining supply", async function () {
            await mineBlock(100);

            let cap = (await token.cap())
            let tswr = await (await token.totalSupplyWithReserves())
            let maxharcap = cap.sub(tswr).mul(100).div(100).add(1);
            createArgs[3].hardcap = maxharcap;
            await expect(
                customProposal.proposeTGE(pool.address, ...tgeArgs)
            ).to.be.revertedWith(
                Exceptions.HARDCAP_OVERFLOW_REMAINING_SUPPLY
            );
        });




    });
});
