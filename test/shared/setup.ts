import { ethers } from "hardhat";

import { ERC20Mock, Service, Registry, CustomProposal } from "../../typechain-types";
import { BASE_JURISDICTION, BASE_ENTITY_TYPE } from "./settings";

const { getContract, getSigners } = ethers;
const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

export async function setup() {
    // Get accounts
    const [owner] = await getSigners();

    // Get contracts
    const service = await getContract<Service>("Service");
    const registry = await getContract<Registry>("Registry");
    const customProposal = await getContract<CustomProposal>("CustomProposal");
    const token1 = await getContract<ERC20Mock>("ONE");

    // Whitelist

    await service.grantRole(
        await service.WHITELISTED_USER_ROLE(),
        owner.address
    );
    await registry.whitelistTokens([AddressZero, token1.address]);
    await registry.grantRole(
        await registry.COMPANIES_MANAGER_ROLE(),
        owner.address
    );

    await service.grantRole(
        await service.EXECUTOR_ROLE(),
        owner.address
    );
    // Mint tokens
    await token1.mint(owner.address, parseUnits("100000"));

    // Create company records
    await registry.createCompany({
        jurisdiction: BASE_JURISDICTION,
        ein: "EIN1",
        dateOfIncorporation: "01.01.2023",
        entityType: BASE_ENTITY_TYPE,
        fee: parseUnits("0.01"),
    });
    await registry.createCompany({
        jurisdiction: BASE_JURISDICTION,
        ein: "EIN2",
        dateOfIncorporation: "01.01.2023",
        entityType: BASE_ENTITY_TYPE,
        fee: parseUnits("0.01"),
    });
}
