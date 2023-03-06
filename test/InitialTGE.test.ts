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
} from "../typechain-types";

import { mineBlock } from "./shared/utils";
import Exceptions from "./shared/exceptions";
import { CreateArgs, makeCreateData } from "./shared/settings";
import { setup } from "./shared/setup";

const { getContract, getContractAt, getSigners, Wallet, provider } = ethers;
const { parseUnits } = ethers.utils;

describe("Test initial TGE", function () {
    let owner: SignerWithAddress,
        other: SignerWithAddress,
        third: SignerWithAddress;
    let service: Service, registry: Registry, vesting: Vesting;
    let pool: Pool, tge: TGE, token: Token;
    let newPool: Pool, newTge: TGE, newToken: Token;
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

        // Setup
        await setup();
    });

    beforeEach(async function () {
        snapshotId = await network.provider.request({
            method: "evm_snapshot",
            params: [],
        });

        // Data
        createArgs = await makeCreateData();
    });

    afterEach(async function () {
        snapshotId = await network.provider.request({
            method: "evm_revert",
            params: [snapshotId],
        });
    });

    describe("Initial TGE: creating for first time", function () {
        it("Only whitelisted can create pool", async function () {

            expect(await registry.isTokenWhitelisted('0x2cDAbA445e942C994F4f1f453f92542aDae68d62')).to.equal(
                false
            );
            await expect(
                service.connect(other).createPool(...createArgs, {
                    value: parseUnits("0.01"),
                })
            ).to.be.reverted;

        });

        it("Can't create pool with incorrect fee", async function () {
            await expect(
                service.createPool(...createArgs, {
                    value: parseUnits("0.005"),
                })
            ).to.be.revertedWith(Exceptions.INCORRECT_ETH_PASSED);
        });

        it("Can't create pool with hardcap higher than token cap", async function () {
            createArgs[3].hardcap = parseUnits("20000");
            await expect(
                service.createPool(...createArgs, {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith(Exceptions.HARDCAP_OVERFLOW_REMAINING_SUPPLY);
        });
    });

    describe("Initial TGE: interaction", function () {
        this.beforeEach(async function () {
            // First TGE
            await service.createPool(...createArgs, {
                value: parseUnits("0.01"),
            });
            let record = await registry.contractRecords(0);
            pool = await getContractAt("Pool", record.addr);
            token = await getContractAt("Token", await pool.getGovernanceToken());
            tge = await getContractAt("TGE", await token.tgeList(0));

            // Second TGE
            createArgs[3].unitOfAccount = token1.address;
            await service.grantRole(
                await service.WHITELISTED_USER_ROLE(),
                owner.address
            );
            await service.createPool(...createArgs, {
                value: parseUnits("0.01"),
            });
            record = await registry.contractRecords(3);
            newPool = await getContractAt("Pool", record.addr);
            newToken = await getContractAt("Token", await newPool.getGovernanceToken());
            newTge = await getContractAt("TGE", await newToken.tgeList(0));
        });

        it("Can't purchase less than min purchase", async function () {
            await expect(
                tge
                    .connect(other)
                    .purchase(1, { value: parseUnits("0.05") })
            ).to.be.revertedWith(Exceptions.MIN_PURCHASE_UNDERFLOW);
        });

        it("Can't purchase with wrong ETH value passed", async function () {
            await expect(
                tge
                    .connect(other)
                    .purchase(parseUnits("50"), { value: parseUnits("0.1") })
            ).to.be.revertedWith(Exceptions.INCORRECT_ETH_PASSED);
        });

        it("Can't purchase over max purchase in one tx", async function () {
            await expect(
                tge
                    .connect(other)
                    .purchase(parseUnits("4000"), { value: parseUnits("40") })
            ).to.be.revertedWith(Exceptions.MAX_PURCHASE_OVERFLOW);
        });

        it("Can't purchase over max purchase in several tx", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("2000"), { value: parseUnits("20") });

            await expect(
                tge
                    .connect(other)
                    .purchase(parseUnits("2000"), { value: parseUnits("20") })
            ).to.be.revertedWith(Exceptions.MAX_PURCHASE_OVERFLOW);
        });

        it("Can't purchase over hardcap", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("3000"), { value: parseUnits("30") });

            await expect(
                tge.purchase(parseUnits("3000"), { value: parseUnits("30") })
            ).to.be.revertedWith(Exceptions.MAX_PURCHASE_OVERFLOW);
        });

        it("Mint can't be called on token directly, should be done though TGE", async function () {
            await expect(
                token.connect(other).mint(other.address, 100)
            ).to.be.revertedWith(Exceptions.NOT_TGE);
        });

        it("Purchasing works", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("1000"), { value: parseUnits("10") });

            expect(await token.balanceOf(other.address)).to.equal(
                parseUnits("500")
            );
            expect(await provider.getBalance(tge.address)).to.equal(
                parseUnits("10")
            );
            expect(await tge.lockedBalanceOf(other.address)).to.equal(
                parseUnits("500")
            );
        });

        it("Purchasing with token (if such is unit of account) works", async function () {
            await token1.mint(other.address, parseUnits("1"));
            await token1
                .connect(other)
                .approve(newTge.address, parseUnits("1"));
            await newTge.connect(other).purchase(parseUnits("100"));

            expect(await newToken.balanceOf(other.address)).to.equal(
                parseUnits("50")
            );
            expect(await newTge.lockedBalanceOf(other.address)).to.equal(
                parseUnits("50")
            );
        });

        it("Can't transfer lockup tokens", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("1000"), { value: parseUnits("10") });

            await expect(
                token.connect(other).transfer(owner.address, parseUnits("1000"))
            ).to.be.revertedWith(Exceptions.LOW_UNLOCKED_BALANCE);
        });

        it("Can't purchase after event is finished", async function () {
            await mineBlock(20);

            await expect(
                tge
                    .connect(other)
                    .purchase(parseUnits("1000"), { value: parseUnits("10") })
            ).to.be.revertedWith(Exceptions.WRONG_STATE);
        });

        it("Can't claim back if event is not failed", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("500"), { value: parseUnits("5") });

            await expect(tge.connect(third).redeem()).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );

            await tge
                .connect(other)
                .purchase(parseUnits("500"), { value: parseUnits("5") });
            await mineBlock(20);

            await expect(tge.connect(third).redeem()).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Claiming back works if TGE is failed", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("400"), { value: parseUnits("4") });

            await mineBlock(20);

            await tge.connect(other).redeem();
            expect(await token.balanceOf(other.address)).to.equal(0);
        });

        it("User can't burn more than his balance", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("400"), { value: parseUnits("4") });
            await mineBlock(20);
            await expect(
                token.connect(other).burn(other.address, parseUnits("500"))
            ).to.be.revertedWith("ERC20: burn amount exceeds balance");
        });

        it("Can't transfer funds if event is not successful", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("500"), { value: parseUnits("5") });

            await expect(tge.transferFunds()).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );

            await mineBlock(20);

            await expect(tge.transferFunds()).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Transferring funds for successful TGE by owner should work", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("1000"), { value: parseUnits("10") });
            await mineBlock(20);

            expect(await tge.totalProtocolFee()).to.equal(
                await (await tge.totalPurchased()).div(100)
            );

            await tge.transferFunds();

            expect(await tge.totalProtocolFee()).to.equal(0);

            expect(await provider.getBalance(pool.address)).to.equal(
                parseUnits("10")
            );
            expect(await token.balanceOf(await service.protocolTreasury())).to.equal(
                await (await tge.totalPurchased()).div(100)
            );
            await (await tge.totalPurchased()).div(100)
        });

        it("In successful TGE purchased funds are still locked until conditions are met", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("1000"), { value: parseUnits("10") });
            await mineBlock(20);
            await tge.transferFunds();

            expect(await tge.lockedBalanceOf(other.address)).to.equal(
                parseUnits("500")
            );
            await expect(
                vesting.connect(other).claim(tge.address)
            ).to.be.revertedWith(Exceptions.CLAIM_NOT_AVAILABLE);
        });
        it("Check getTotalVestedValue and getTotalPurchasedValue", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("1000"), { value: parseUnits("10") });

            expect(
                await tge.getTotalVestedValue()
            ).to.be.equal(parseUnits("5"));

            expect(
                await tge.getTotalPurchasedValue()
            ).to.be.equal(parseUnits("10"));


        });

        it("Funds are still locked if only TVL condition is met", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("2000"), { value: parseUnits("20") });
            await mineBlock(20);

            await tge.transferFunds();
            await tge.setLockupTVLReached();

            expect(await tge.lockedBalanceOf(other.address)).to.equal(
                parseUnits("1000")
            );
            await expect(
                vesting.connect(other).claim(tge.address)
            ).to.be.revertedWith(Exceptions.CLAIM_NOT_AVAILABLE);
        });

        it("Funds are still locked if only duration condition is met", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("1000"), { value: parseUnits("10") });
            await mineBlock(20);

            expect(await tge.lockedBalanceOf(other.address)).to.equal(
                parseUnits("500")
            );
            await expect(
                vesting.connect(other).claim(tge.address)
            ).to.be.revertedWith(Exceptions.CLAIM_NOT_AVAILABLE);
        });

        it("Vested funds can be unlocked as soon as all unlocked conditions are met", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("2000"), { value: parseUnits("20") });
            await mineBlock(400);
            await tge.transferFunds();
            await vesting.setClaimTVLReached(tge.address);

            await vesting.connect(other).claim(tge.address);
            expect(await tge.lockedBalanceOf(other.address)).to.equal(
                parseUnits("2000")
            );
            expect(await token.balanceOf(other.address)).to.equal(
                parseUnits("2000")
            );
        });

        it("Token has zero decimals", async function () {
            expect(await token.decimals()).to.equal(18);
        });

        it("Only service owner or manager can whitelist", async function () {
            await expect(
                service
                    .connect(other)
                    .grantRole(
                        await service.WHITELISTED_USER_ROLE(),
                        other.address
                    )
            ).to.be.revertedWith(
                "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x2b1db18cd92cf6947e9bb2f532380e05e806a043d20a65c532268a1d7f4b5e73"
            );
        });

        it("Only owner can transfer funds", async function () {
            await expect(
                service.connect(other).transferCollectedFees(other.address)
            ).to.be.revertedWith(
                "AccessControl: account 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
            );
        });

        it("Transferring funds work", async function () {
            const treasury = Wallet.createRandom();
            await service.transferCollectedFees(treasury.address);
            expect(await provider.getBalance(treasury.address)).to.equal(
                parseUnits("0.02")
            );
        });
    });

    describe("Failed TGE: redeeming & recreating", async function () {
        this.beforeEach(async function () {
            // First TGE
            await service.createPool(...createArgs, {
                value: parseUnits("0.01"),
            });
            const record = await registry.contractRecords(0);
            pool = await getContractAt("Pool", record.addr);
            token = await getContractAt("Token", await pool.getGovernanceToken());
            tge = await getContractAt("TGE", await token.tgeList(0));

            // Buy from TGE
            await tge
                .connect(other)
                .purchase(parseUnits("500"), { value: parseUnits("5") });

            createArgs[0] = pool.address;
        });

        it("Can't redeem from active TGE", async function () {
            expect(await tge.redeemableBalanceOf(other.address)).to.equal(0);
            await expect(tge.connect(other).redeem()).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Can't redeem from successfull TGE", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("500"), { value: parseUnits("5") });
            await mineBlock(20);

            expect(await tge.redeemableBalanceOf(other.address)).to.equal(0);
            await expect(tge.connect(other).redeem()).to.be.revertedWith(
                Exceptions.WRONG_STATE
            );
        });

        it("Redeeming from failed TGE works", async function () {
            expect(await tge.redeemableBalanceOf(other.address)).to.equal(0);
            await mineBlock(20);

            const balanceBefore = await other.getBalance();
            expect(await tge.redeemableBalanceOf(other.address)).to.equal(
                parseUnits("500")
            );
            await tge.connect(other).redeem();
            const balanceAfter = await other.getBalance();

            expect(await tge.redeemableBalanceOf(other.address)).to.equal(0);
            expect(await token.balanceOf(other.address)).to.equal(0);
            expect(
                await vesting.vestedBalanceOf(tge.address, other.address)
            ).to.equal(0);
            expect(balanceAfter.sub(balanceBefore)).to.be.gt(
                parseUnits("4.999") // Adjusted for spent gas fees
            );
        });

        it("Can't recreate TGE for non-pool", async function () {
            createArgs[0] = token.address;
            await expect(
                service.connect(other).createPool(...createArgs, {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith(Exceptions.NOT_POOL);
        });

        it("Only pool owner can recreate TGE", async function () {
            await expect(
                service.connect(other).createPool(...createArgs, {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith(Exceptions.NOT_POOL_OWNER);
        });

        it("Can't recreate successful TGE", async function () {
            await tge
                .connect(other)
                .purchase(parseUnits("1000"), { value: parseUnits("10") });
            await mineBlock(20);

            await expect(
                service.createPool(...createArgs, {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith(Exceptions.IS_DAO);
        });

        it("Failed TGE can be recreated", async function () {
            await mineBlock(20);

            // TGE is failed

            expect(await pool.isDAO()).to.be.false;

            createArgs[1] = parseUnits("20000");
            createArgs[2] = "DTKN2";

            await service.createPool(...createArgs);
            const record = await registry.contractRecords(0);
            const newPool = await getContractAt("Pool", record.addr);
            const newToken = await getContractAt(
                "Token",
                await newPool.getGovernanceToken()
            );
            const newTge = await getContractAt(
                "TGE",
                await newToken.tgeList(0)
            );

            // Pool should remain the same, token and TGE should be new

            expect(newPool.address).to.equal(pool.address);
            expect(newToken.address).not.to.equal(token.address);
            expect(newTge.address).not.to.equal(tge.address);

            expect(await newToken.name()).to.equal("Name"); // pool.getTrademark()
            expect(await newToken.symbol()).to.equal("DTKN2");
            expect(await newToken.cap()).to.equal(parseUnits("20200")); // Cap with fee
        });
    });
});
