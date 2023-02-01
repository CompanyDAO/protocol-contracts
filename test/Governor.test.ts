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

describe("Test Governor", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        second: SignerWithAddress,
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
        [owner, other,second, third, fourth] = await getSigners();

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
            other.address,
            second.address,
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
            tgeArgs = await makeTGEArgs(createArgs[3]);
            tx = await pool.proposeTGE(...tgeArgs);
        });

        it("Token delegation works", async function () {
            await mineBlock(1);
            const startVotes_donor = await token.getVotes(other.address);
            const startVotes_rec = await token.getVotes(second.address);
            expect(startVotes_rec).to.equal(parseUnits("0"));
            await token.connect(other).delegate(second.address);
            await mineBlock(2);
            const finishVotes_donor = await token.getVotes(other.address);

            expect(finishVotes_donor).to.equal(parseUnits("0"));
            expect(startVotes_rec).to.equal(finishVotes_donor );
            await token.connect(other).delegate(other.address);
            await mineBlock(2);
            expect(await token.getVotes(other.address)).to.equal(startVotes_donor );
        });

        it("Can't vote with tokens delegated after start of voting", async function () {
            await token.connect(other).delegate(second.address);
            await expect(
                pool.connect(second).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Can't vote with no delegated or governance tokens", async function () {
            expect(await token.balanceOf(second.address)).to.equal(
                parseUnits("0")
            );
            await expect(
                pool.connect(second).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Can't vote with governance tokens transferred after voting started", async function () {
            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(
                true
            );

            await mineBlock(1);
            const VotesDelegateDonor = await token.getVotes(third.address);
            const VotesTransferDonor = await token.getVotes(other.address);
            await token.connect(other).transfer(second.address, await token.balanceOf(other.address));
            await token.connect(third).delegate(second.address);

            // new transfer proposal
            await pool.connect(owner).proposeTransfer(
                AddressZero,
                [third.address, fourth.address],
                [parseUnits("0.1"), parseUnits("0.1")],
                "Let's give them money",
                "#"
            );
            await mineBlock(1);

            await token.connect(second).transfer(other.address, await token.balanceOf(second.address));
            await mineBlock(1);
            await expect(
                pool.connect(other).castVote(2, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
            await pool.connect(second).castVote(2, true);
            await mineBlock(1);
            const TransferProposal = await pool.proposals(2);

            expect(TransferProposal.vote.forVotes).to.equal(VotesDelegateDonor.add(VotesTransferDonor));
        });

        it("Can't vote twice on the same proposal", async function () {
            await pool.connect(other).castVote(1, true);
            await mineBlock(2);
            await expect(
                pool.connect(other).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ALREADY_VOTED);
        });

        it("Can't vote twice on the same proposal in the same block", async function () {
            await pool.connect(other).castVote(1, true);
            await expect(
                pool.connect(other).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ALREADY_VOTED);
        });

        it("Ballot BEFORE token transfer eq Ballot AFTER token transfer", async function () {
            await mineBlock(2);
            const startBallot = await pool.getBallot(second.address, 1);
            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(
                true
            );
            await token.connect(other).transfer(second.address, await token.balanceOf(other.address));
            const finishBallot = await pool.getBallot(second.address, 1);
            await mineBlock(2);
            expect(startBallot[0]).to.equal(finishBallot[0]);
        });

        it("Can't transfer tokens twice in the same block", async function () {
            await pool.connect(other).castVote(1, true);
            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(
                true
            );
            const otherTokenBalance = await token.balanceOf(other.address);
            await token.connect(other).transfer(second.address, otherTokenBalance);
            await expect(
                token.connect(other).transfer(second.address, otherTokenBalance)
            ).to.be.revertedWith(Exceptions.LOW_UNLOCKED_BALANCE);
        });

        it("Can't vote twice with the same tokens", async function () {
            await pool.connect(other).castVote(1, true);
            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(
                true
            );
            await token.connect(other).transfer(second.address, await token.balanceOf(other.address));
            await expect(
                pool.connect(second).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Recipient can't vote if proposal created in the same block with the governance token transfer", async function () {
            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(true);
            await pool.connect(other).proposeTGE(...tgeArgs);
            await token.connect(other).transfer(second.address, await token.balanceOf(other.address));
            await mineBlock(10);
            await expect(
                pool.connect(second).castVote(2, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Can't execute inevitably successful proposal before voting period is finished and BEFORE delay passed", async function () {
            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);

            await expect(pool.executeProposal(1)).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Executed TGE proposal can't change token cap ", async function () {

            await mineBlock(2);
            // new proposeTransfer
           await pool.connect(other).proposeTransfer(
                AddressZero,
                [third.address, fourth.address],
                [parseUnits("0.1"), parseUnits("0.1")],
                "Let's give them money",
                "#"
            );
            await mineBlock(2);
            const startTokenCap = await token.cap();

            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);
            await mineBlock(2);

            // success execute Proposal of TGE
            await pool.executeProposal(1);
            const tgeRecord = await registry.contractRecords(3);
            const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

            // owner purchase new tokens from TGE
            await tge2
                .connect(owner)
                .purchase(parseUnits("10"), { value: parseUnits("1") });

            await mineBlock(10);


            expect(startTokenCap).to.equal(await token.cap());


            // owner burn new tokens from TGE
            await token
            .connect(owner)
            .burn(owner.address,parseUnits("10"));

            expect(startTokenCap).to.equal(await token.cap());
        });

        it("Burning tokens from TGE can't affect new proposals", async function () {

            const TGEproposal = await pool.proposals(1);

            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);
            await mineBlock(1);
            // success execute Proposal of TGE
            await pool.executeProposal(1);
            const tgeRecord = await registry.contractRecords(3);
            const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

            // owner purchase new tokens from TGE
            await tge2
                .connect(owner)
                .purchase(parseUnits("100"), { value: parseUnits("10") });

            await mineBlock(2);

            // owner burn new tokens from TGE
             await token
             .connect(owner)
             .burn(owner.address,parseUnits("50"));

            await mineBlock(2);

             // new transfer proposal
            await pool.connect(other).proposeTransfer(
                AddressZero,
                [third.address, fourth.address],
                [parseUnits("0.1"), parseUnits("0.1")],
                "Let's give them money",
                "#"
            );
            await mineBlock(1);
            const TransferProposal = await pool.proposals(2);

            expect(TGEproposal.vote.availableVotes).to.equal(TransferProposal.vote.availableVotes);
        });

        it("Can't vote with tokens purchased after start of voting", async function () {

            const TGEproposal = await pool.proposals(1);

            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);
            await mineBlock(1);
            // success execute Proposal of TGE
            await pool.executeProposal(1);
            const tgeRecord = await registry.contractRecords(3);
            const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

            // new transfer proposal
            await pool.connect(other).proposeTransfer(
                AddressZero,
                [third.address, fourth.address],
                [parseUnits("0.1"), parseUnits("0.1")],
                "Let's give them money",
                "#"
            );
            await mineBlock(1);
            // owner purchase new tokens from TGE
            await tge2
                .connect(second)
                .purchase(parseUnits("10"), { value: parseUnits("1") });

            await mineBlock(2);
            await expect(
                pool.connect(second).castVote(2, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        
        it("Purchasing tokens from TGE can't affect current Active proposals", async function () {           
            // new transfer proposal
            await pool.connect(other).proposeTransfer(
                AddressZero,
                [third.address, fourth.address],
                [parseUnits("0.1"), parseUnits("0.1")],
                "Let's give them money",
                "#"
            );
            await mineBlock(2);
            const startTransferProposal = await pool.proposals(2);
            await pool.connect(owner).castVote(1, true);
            await pool.connect(other).castVote(1, true);
            await mineBlock(1);
            // success execute Proposal of TGE
            await pool.executeProposal(1);
            const tgeRecord = await registry.contractRecords(3);
            const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

            // owner purchase new tokens from TGE
            await tge2
                .connect(second)
                .purchase(parseUnits("10"), { value: parseUnits("1") });
            await mineBlock(1);
            await pool.connect(owner).castVote(2, true);
            await mineBlock(1);
            const finishTransferProposal = await pool.proposals(2);
            expect(startTransferProposal.vote.availableVotes).to.equal(finishTransferProposal.vote.availableVotes);
        });
    });
});