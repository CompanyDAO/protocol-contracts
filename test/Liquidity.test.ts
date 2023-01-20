import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { deployments, ethers, network } from "hardhat";
import { ERC20Mock, IQuoter, IWETH } from "../typechain-types";
import { setup } from "./shared/setup";

const { getContractAt, getSigners } = ethers;
const { parseUnits } = ethers.utils;

describe("Test uniswap liquidity setup", function () {
    let token1: ERC20Mock,
        token2: ERC20Mock,
        token3: ERC20Mock,
        weth: IWETH,
        quoter: IQuoter;
    let snapshotId: any;

    // before(async function () {
    //     await deployments.fixture();

    //     // Setup
    //     ({ token1, token2, token3 } = await setup());

    //     const WETH_ADDRESS = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
    //     weth = await getContractAt("IWETH", WETH_ADDRESS);

    //     const UNISWAP_QUOTER_ADDRESS =
    //         "0xb27308f9f90d607463bb33ea1bebb41c27ce5ab6";
    //     quoter = await getContractAt("IQuoter", UNISWAP_QUOTER_ADDRESS);
    // });

    // beforeEach(async function () {
    //     snapshotId = await network.provider.request({
    //         method: "evm_snapshot",
    //         params: [],
    //     });
    // });

    // afterEach(async function () {
    //     snapshotId = await network.provider.request({
    //         method: "evm_revert",
    //         params: [snapshotId],
    //     });
    // });

    // it("Liquidity ONE - ETH is correct", async function () {
    //     const amountOut = await quoter.callStatic.quoteExactInputSingle(
    //         token1.address,
    //         weth.address,
    //         500,
    //         parseUnits("10"),
    //         0
    //     );

    //     // In pool there are 20000 ONE and 100 ETH, so 200 ONE ~ 1 ETH, so 10 ONE ~ 0.05 ETH
    //     expect(amountOut).to.be.gt(parseUnits("0.0499"));
    // });

    // it("Liqudiity TWO - ONE is correct", async function () {
    //     const amountOut = await quoter.callStatic.quoteExactInputSingle(
    //         token2.address,
    //         token1.address,
    //         500,
    //         parseUnits("1"),
    //         0
    //     );

    //     // In pool there are 200000 ONE and 100000 TWO, so 1 TWO ~ 2 ONE
    //     expect(amountOut).to.be.gt(parseUnits("1.99"));
    // });

    // it("Liquidity THREE - ETH is correct", async function () {
    //     const amountOut = await quoter.callStatic.quoteExactInputSingle(
    //         token3.address,
    //         weth.address,
    //         500,
    //         parseUnits("1"),
    //         0
    //     );

    //     // In pool there are 1000 THREE and 100 ETH, so 1 THREE ~ 0.1 ETH
    //     expect(amountOut).to.be.gt(parseUnits("0.099"));
    // });
});
