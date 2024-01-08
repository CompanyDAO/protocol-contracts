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
  IDRegistry
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
  let service: Service,
    registry: Registry,
    IDRegistry: IDRegistry,
    vesting: Vesting,
    tgeFactory: TGEFactory;
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
    IDRegistry = await getContract("IDRegistry");
    vesting = await getContract("Vesting");
    token1 = await getContract("ONE");
    tgeFactory = await getContract("TGEFactory");

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
    it("Can't purchase pool with incorrect fee", async function () {
      await expect(
        service.purchasePool(
          createArgs[4],
          createArgs[5],
          createArgs[2],
          createArgs[6],
          {
            value: parseUnits("0.05"),
          }
        )
      ).to.be.revertedWith(Exceptions.INCORRECT_ETH_PASSED);
    });
  });

  describe("Initial TGE for permissioned tokens: interaction", function () {
    this.beforeEach(async function () {
      // First TGE
      await service.purchasePool(
        createArgs[4],
        createArgs[5],
        createArgs[2],
        createArgs[6],
        {
          value: parseUnits("0.01"),
        }
      );
      let record = await registry.contractRecords(1);
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

      await token.setCompliance( ethers.utils.formatBytes32String("marsbase"));

      await IDRegistry.addComplianceAdmin(owner.address,ethers.utils.formatBytes32String("marsbase"))

      await IDRegistry.addToWhitelist(owner.address,ethers.utils.formatBytes32String("marsbase"))

      await IDRegistry.addToWhitelist(other.address,ethers.utils.formatBytes32String("marsbase"))

      tge = await getContractAt("TGE", await token.tgeList(0));

     
      
    });

    it("Can't purchase less than min purchase", async function () {
      await expect(
        tge.connect(other).purchase(1, { value: parseUnits("0.1") })
      ).to.be.revertedWith(Exceptions.INVALID_PURCHASE_AMOUNT);
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
      ).to.be.revertedWith(Exceptions.INVALID_PURCHASE_AMOUNT);
    });

    it("Can't purchase over max purchase in several tx", async function () {
      await tge
        .connect(other)
        .purchase(parseUnits("2000"), { value: parseUnits("20") });

      await expect(
        tge
          .connect(other)
          .purchase(parseUnits("2000"), { value: parseUnits("20") })
      ).to.be.revertedWith(Exceptions.INVALID_PURCHASE_AMOUNT);
    });

    it("Can't purchase over hardcap", async function () {
      await tge
        .connect(other)
        .purchase(parseUnits("3000"), { value: parseUnits("30") });

      await expect(
        tge.purchase(parseUnits("3000"), { value: parseUnits("30") })
      ).to.be.revertedWith(Exceptions.INVALID_PURCHASE_AMOUNT);
    });

    it("Mint can't be called on token directly, should be done though TGE", async function () {
      await expect(
        token.connect(other).mint(other.address, 100)
      ).to.be.revertedWith(Exceptions.NOT_TGE);
    });

    it("Purchasing works", async function () {

      
      let tx = await tge
        .connect(other)
        .purchase(parseUnits("1000"), { value: parseUnits("10") });
      
        let receipt = await tx.wait();

        if (receipt.events) {
           // index = receipt.events[5].args?.index;
           //console.log(receipt.events);
        }


      expect(await token.balanceOf(other.address)).to.equal(parseUnits("500"));
      expect(await provider.getBalance(tge.address)).to.equal(parseUnits("10"));
      expect(await tge.lockedBalanceOf(other.address)).to.equal(
        parseUnits("500")
      );
    });

    it("Purchasing with token (if such is unit of account) works", async function () {
      await mineBlock(50);
      createArgs[3].unitOfAccount = token1.address;
      await service.grantRole(
        await service.WHITELISTED_USER_ROLE(),
        owner.address
      );
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

      newToken = await getContractAt("Token", await pool.getGovernanceToken());
      newTge = await getContractAt("TGE", await newToken.tgeList(0));

      await token1.mint(other.address, parseUnits("1"));

      await token1.connect(other).approve(newTge.address, parseUnits("1"));
      await newTge.connect(other).purchase(parseUnits("100"));

      expect(await newToken.balanceOf(other.address)).to.equal(
        parseUnits("50")
      );
      expect(await newTge.lockedBalanceOf(other.address)).to.equal(
        parseUnits("50")
      );
    });

    it("Can't purchase over max purchase in one tx", async function () {
      await expect(
        tge
          .connect(other)
          .purchase(parseUnits("4000"), { value: parseUnits("40") })
      ).to.be.revertedWith(Exceptions.INVALID_PURCHASE_AMOUNT);
    });

    it("Can't purchase over max purchase in several tx", async function () {
      await tge
        .connect(other)
        .purchase(parseUnits("2000"), { value: parseUnits("20") });

      await expect(
        tge
          .connect(other)
          .purchase(parseUnits("2000"), { value: parseUnits("20") })
      ).to.be.revertedWith(Exceptions.INVALID_PURCHASE_AMOUNT);
    });

    it("Can't purchase over hardcap", async function () {
      await tge
        .connect(other)
        .purchase(parseUnits("3000"), { value: parseUnits("30") });

      await expect(
        tge.purchase(parseUnits("3000"), { value: parseUnits("30") })
      ).to.be.revertedWith(Exceptions.INVALID_PURCHASE_AMOUNT);
    });

    it("Mint can't be called on token directly, should be done though TGE", async function () {
      await expect(
        token.connect(other).mint(other.address, 100)
      ).to.be.revertedWith(Exceptions.NOT_TGE);
    });

    it("Purchasing works", async function () {
      expect(await (await tge.getUserWhitelist()).length).to.equal(2);
      await tge
        .connect(other)
        .purchase(parseUnits("1000"), { value: parseUnits("10") });

      expect(await token.balanceOf(other.address)).to.equal(parseUnits("500"));
      expect(await provider.getBalance(tge.address)).to.equal(parseUnits("10"));
      expect(await tge.lockedBalanceOf(other.address)).to.equal(
        parseUnits("500")
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

    // it.only("Claiming back works if TGE is failed", async function () {
    //   await tge
    //     .connect(other)
    //     .purchase(parseUnits("400"), { value: parseUnits("4") });

    //   await mineBlock(20);

    //   expect(await provider.getBalance(pool.address)).to.equal(
    //     parseUnits("10")
    //   );
    //   expect(
    //     await token.balanceOf(await service.protocolTreasury())
    //   ).to.equal(await (await tge.totalPurchased()).div(100));
    // });

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

      expect(await tge.getTotalVestedValue()).to.be.equal(parseUnits("5"));

      expect(await tge.getTotalPurchasedValue()).to.be.equal(parseUnits("10"));
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
      await (await tge.totalPurchased()).div(100);
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
        parseUnits("0.01")
      );
    });
  });

  describe("Failed TGE: redeeming & recreating", async function () {
    this.beforeEach(async function () {
      // First TGE
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

    /*it("Can't recreate TGE for non-pool", async function () {
            createArgs[0] = token.address;
            await expect(
                service.connect(other).createPool(...createArgs, {
                    value: parseUnits("0.01"),
                })
            ).to.be.revertedWith(Exceptions.NOT_POOL);
        });*/

    it("Only pool owner can recreate TGE", async function () {
      await expect(
        tgeFactory.connect(other).createPrimaryTGE(
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
        )
      ).to.be.revertedWith(Exceptions.NOT_POOL_OWNER);
    });

    it("Can't recreate successful TGE", async function () {
      await tge
        .connect(other)
        .purchase(parseUnits("1000"), { value: parseUnits("10") });
      await mineBlock(20);

      await expect(
        tgeFactory.createPrimaryTGE(
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
        )
      ).to.be.revertedWith(Exceptions.GOVERNANCE_TOKEN_EXISTS);
    });

    it("Failed TGE can be recreated", async function () {
      await mineBlock(20);

      // TGE is failed

      expect(await pool.isDAO()).to.be.false;

      await tgeFactory.createPrimaryTGE(
        pool.address,
        {
          tokenType: 1,
          cap: parseUnits("20000"),
          name: createArgs[2],
          symbol: "DTKN2",
          description: "",
          decimals: 18,
        },
        createArgs[3],
        createArgs[8],
        createArgs[6],
        [owner.address],
        [owner.address]
      );
      const newToken = await getContractAt(
        "Token",
        await pool.getGovernanceToken()
      );

      expect(await newToken.symbol()).to.equal("DTKN2");
      expect(await newToken.cap()).to.equal(parseUnits("20000")); // Cap with fee
    });
  });
});
