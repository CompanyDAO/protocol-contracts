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
} from "../test/shared/settings";
import { mineBlock } from "../test/shared/utils";
import { setup } from "../test/shared/setup";

const { getContractAt, getContract, getSigners } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

describe("Test Governor", function () {
    let owner: SignerWithAddress,
        donor: SignerWithAddress,
        recipient: SignerWithAddress,
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
        [owner, donor, recipient, third, fourth] = await getSigners();

        // Fixture
        await deployments.fixture();

        // Get contracts
        service = await getContract("Service");
        registry = await getContract("Registry");
        customProposal = await getContract("CustomProposal");
        token1 = await getContract("ONE");
        tgeFactory = await getContract("TGEFactory");

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
        createArgs[3].userWhitelistMin = [
            0,0,0,0
        ];
        createArgs[3].userWhitelistMax = [
            0,0,0,0
        ];
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

    describe("Secondary TGE for governance token", async function () {
        this.beforeEach(async function () {
            // Propose secondary TGE
            tgeArgs = await makeTGEArgs(token.address, createArgs[3]);
            await customProposal.proposeTGE(pool.address, ...tgeArgs);
        });

        it("Token delegation works", async function () {
            await mineBlock(1);
            const startVotes_donor = await token.getVotes(donor.address);
            const startVotes_rec = await token.getVotes(recipient.address);
            expect(startVotes_rec).to.equal(parseUnits("0"));
            await token.connect(donor).delegate(recipient.address);
            await mineBlock(2);
            const finishVotes_donor = await token.getVotes(donor.address);
            const finishVotes_rec = await token.getVotes(recipient.address);

            expect(finishVotes_donor).to.equal(parseUnits("0"));

            expect(startVotes_donor).to.equal(finishVotes_rec);
            await token.connect(donor).delegate(donor.address);
            await mineBlock(2);
            expect(await token.getVotes(donor.address)).to.equal(
                startVotes_donor
            );
        });

        it("Can't vote with tokens delegated after start of voting", async function () {
            //waiting for voting start
            await mineBlock(10);

            await token.connect(donor).delegate(recipient.address);
            await expect(
                pool.connect(recipient).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Can't vote with no delegated or governance tokens", async function () {
            //waiting for voting start
            await mineBlock(10);

            expect(await token.balanceOf(recipient.address)).to.equal(
                parseUnits("0")
            );
            await expect(
                pool.connect(recipient).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Can't vote with governance tokens transferred after voting started", async function () {
            //waiting for voting start
            await mineBlock(10);

            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(true);

            await mineBlock(1);
            const VotesDelegateDonor = await token.getVotes(third.address);
            const VotesTransferDonor = await token.getVotes(donor.address);
            await token
                .connect(donor)
                .transfer(
                    recipient.address,
                    await token.balanceOf(donor.address)
                );
            await token.connect(third).delegate(recipient.address);

            // new transfer proposal
            await customProposal
                .connect(owner)
                .proposeTransfer(
                    pool.address,
                    AddressZero,
                    [third.address, fourth.address],
                    [parseUnits("0.1"), parseUnits("0.1")],
                    "Let's give them money",
                    "#"
                );
            await mineBlock(1);
            await mineBlock(10);
            await token
                .connect(recipient)
                .transfer(
                    donor.address,
                    await token.balanceOf(recipient.address)
                );
            await mineBlock(1);

            //waiting for voting start

            await expect(
                pool.connect(donor).castVote(2, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
            await pool.connect(recipient).castVote(2, true);
            await mineBlock(1);
            const TransferProposal = await pool.proposals(2);

            expect(TransferProposal.vote.forVotes).to.equal(
                VotesDelegateDonor.add(VotesTransferDonor)
            );
        });

        it("Can't vote twice on the same proposal", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(donor).castVote(1, true);
            await mineBlock(2);
            await expect(
                pool.connect(donor).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ALREADY_VOTED);
        });

        it("Can't vote twice on the same proposal in the same block", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(donor).castVote(1, true);
            await expect(
                pool.connect(donor).castVote(1, true)
            ).to.be.revertedWith(Exceptions.ALREADY_VOTED);
        });

        it("Ballot BEFORE token transfer eq Ballot AFTER token transfer", async function () {
            //waiting for voting start
            await mineBlock(10);

            await mineBlock(2);
            const startBallot = await pool.getBallot(recipient.address, 1);
            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(true);
            await token
                .connect(donor)
                .transfer(
                    recipient.address,
                    await token.balanceOf(donor.address)
                );
            const finishBallot = await pool.getBallot(recipient.address, 1);
            await mineBlock(2);
            expect(startBallot[0]).to.equal(finishBallot[0]);
        });

        it("Can't transfer tokens twice in the same block", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(donor).castVote(1, true);
            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(true);
            const otherTokenBalance = await token.balanceOf(donor.address);
            await token
                .connect(donor)
                .transfer(recipient.address, otherTokenBalance);
            await expect(
                token
                    .connect(donor)
                    .transfer(recipient.address, otherTokenBalance)
            ).to.be.revertedWith(Exceptions.LOW_UNLOCKED_BALANCE);
        });

        it("Can't vote twice with the same tokens", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(donor).castVote(1, true);
            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(true);
            await mineBlock(2);
            // new proposeTransfer
            await customProposal
                .connect(donor)
                .proposeTransfer(
                    pool.address,
                    AddressZero,
                    [third.address, fourth.address],
                    [parseUnits("0.1"), parseUnits("0.1")],
                    "Let's give them money",
                    "#"
                );
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(donor).castVote(2, true);
            await token
                .connect(donor)
                .transfer(
                    recipient.address,
                    await token.balanceOf(donor.address)
                );

            await expect(
                pool.connect(donor).castVote(2, true)
            ).to.be.revertedWith(Exceptions.ALREADY_VOTED);

            await expect(
                pool.connect(recipient).castVote(2, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Recipient can't vote if proposal created in the same block with the governance token transfer", async function () {
            await mineBlock(51);
            await tge.setLockupTVLReached();
            expect(await tge.transferUnlocked()).to.equal(true);
            await customProposal.proposeTGE(pool.address, ...tgeArgs);
            await mineBlock(10);
            await token
                .connect(donor)
                .transfer(
                    recipient.address,
                    await token.balanceOf(donor.address)
                );

            await token
                .connect(donor)
                .transfer(
                    recipient.address,
                    await token.balanceOf(donor.address)
                );
            await expect(
                pool.connect(recipient).castVote(2, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Can't execute inevitably successful proposal before voting period is finished and BEFORE delay passed", async function () {
            //waiting for voting start
            await mineBlock(10);

            await pool.connect(owner).castVote(1, true);
            await pool.connect(donor).castVote(1, true);

            await expect(pool.executeProposal(1)).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Executed TGE proposal can't change token cap", async function () {
            //waiting for voting start
            await mineBlock(10);

            await mineBlock(2);
            // new proposeTransfer
            await customProposal
                .connect(donor)
                .proposeTransfer(
                    pool.address,
                    AddressZero,
                    [third.address, fourth.address],
                    [parseUnits("0.1"), parseUnits("0.1")],
                    "Let's give them money",
                    "#"
                );
            await mineBlock(2);
            const startTokenCap = await token.cap();

            await pool.connect(owner).castVote(1, true);
            await pool.connect(donor).castVote(1, true);
            await mineBlock(2);

            // success execute Proposal of TGE
            await pool.executeProposal(1);
            const tgeRecord = await registry.contractRecords(4);


            const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

            // owner purchase new tokens from TGE
            await tge2
                .connect(owner)
                .purchase(parseUnits("10"), { value: parseUnits("1") });

            await mineBlock(10);

            expect(startTokenCap).to.equal(await token.cap());

            // owner burn new tokens from TGE
            await token.connect(owner).burn(owner.address, parseUnits("10"));

            expect(startTokenCap).to.equal(await token.cap());
        });

        it("Can't vote with tokens purchased after start of voting", async function () {
            //waiting for voting start
            await mineBlock(10);
            const TGEproposal = await pool.proposals(1);

            await pool.connect(owner).castVote(1, true);
            await pool.connect(donor).castVote(1, true);
            await mineBlock(1);
            // success execute Proposal of TGE
            await pool.executeProposal(1);
            const tgeRecord = await registry.contractRecords(4);
            const tge2: TGE = await getContractAt("TGE", tgeRecord.addr);

            // new transfer proposal
            await customProposal
                .connect(donor)
                .proposeTransfer(
                    pool.address,
                    AddressZero,
                    [third.address, fourth.address],
                    [parseUnits("0.1"), parseUnits("0.1")],
                    "Let's give them money",
                    "#"
                );
            await mineBlock(1);
            //waiting for voting start
            await mineBlock(10);
            // owner purchase new tokens from TGE
            await tge2
                .connect(recipient)
                .purchase(parseUnits("10"), { value: parseUnits("1") });

            await mineBlock(2);

            await expect(
                pool.connect(recipient).castVote(2, true)
            ).to.be.revertedWith(Exceptions.ZERO_VOTES);
        });

        it("Can propose and execute proposeGovernanceSettings", async function () {
            let createData = await makeCreateData();
            createData[6].votingStartDelay = 5;
            createData[6].proposalThreshold = 1;

            await customProposal
                .connect(owner)
                .proposeGovernanceSettings(
                    pool.address,
                    createData[6],
                    "description",
                    "hash"
                );

            await mineBlock(11);

            await pool.connect(owner).castVote(2, true);
            await pool.connect(donor).castVote(2, true);
            await mineBlock(5);
            // success execute Proposal

            await pool.executeProposal(2);

            expect(await pool.votingStartDelay()).to.equal(5);
        });

        it("Can't proposeGovernanceSettings if another one is Active", async function () {
            let createData = await makeCreateData();
            createData[6].votingStartDelay = 5;
            await customProposal
                .connect(donor)
                .proposeGovernanceSettings(
                    pool.address,
                    createData[6],
                    "description",
                    "hash"
                );

            await mineBlock(10);
            await expect(
                customProposal
                    .connect(donor)
                    .proposeGovernanceSettings(
                        pool.address,
                        createData[6],
                        "description",
                        "hash"
                    )
            ).to.be.revertedWith(
                Exceptions.ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS
            );
        });
        it("Can propose and execute proposeGovernanceSettingswithRoles", async function () {
            let createData = await makeCreateData();
            createData[6].votingStartDelay = 5;
            createData[6].proposalThreshold = 1;

            await customProposal
                .connect(owner)
                .proposeGovernanceSettingsWithRoles(
                    pool.address,
                    createData[6],
                    [third.address],
                    [third.address],
                    "description",
                    "hash"
                );

            await mineBlock(11);

            await pool.connect(owner).castVote(2, true);
            await pool.connect(donor).castVote(2, true);
            await mineBlock(5);
            // success execute Proposal
            
            expect(await pool.isValidExecutor(owner.address)).to.equal(true);
             await pool.executeProposal(2);

            expect(await pool.votingStartDelay()).to.equal(5);
                
            expect(await pool.isPoolExecutor(third.address)).to.equal(true);
            expect(await pool.isPoolSecretary(third.address)).to.equal(true);
        });
       
    });
});
