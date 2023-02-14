import { BigNumberish } from "ethers";
import { ethers } from "hardhat";

import { NewGovernanceSettingsStruct } from "../../typechain-types/GovernanceSettings";
import { TGEInfoStruct } from "../../typechain-types/GovernorProposals";
import { TokenInfoStruct } from "../../typechain-types/Service";

const { parseUnits } = ethers.utils;
const { AddressZero } = ethers.constants;

export type CreateArgs = [
    string,
    BigNumberish,
    string,
    TGEInfoStruct,
    number,
    number,
    NewGovernanceSettingsStruct,
    string,
    string
];

export type TGEArgs = [TGEInfoStruct, TokenInfoStruct, string, string, string];

export const BASE_JURISDICTION = 1;
export const BASE_ENTITY_TYPE = 1;

export async function makeCreateData(): Promise<CreateArgs> {
    const [owner, other] = await ethers.getSigners();

    const tgeData = {
        price: parseUnits("0.01"),
        hardcap: parseUnits("5000"),
        softcap: parseUnits("1000"),
        minPurchase: parseUnits("10"),
        maxPurchase: parseUnits("3000"),
        vestingPercent: 500000,
        vestingDuration: 100,
        vestingTVL: parseUnits("100"),
        lockupDuration: 50,
        lockupTVL: parseUnits("20"),
        duration: 20,
        userWhitelist: [owner.address, other.address],
        unitOfAccount: AddressZero,
    };
    const settings: NewGovernanceSettingsStruct = {
        proposalThreshold: 100000, // 10%
        quorumThreshold: 400000, // 40%
        decisionThreshold: 500000, // 50%
        votingDuration: 55,
        transferValueForDelay: 0,
        executionDelays: [2, 0, 0, 0],
        votingStartDelay: 10
    };

    return [
        AddressZero,
        parseUnits("10000"),
        "DAO",
        tgeData,
        BASE_JURISDICTION,
        BASE_ENTITY_TYPE,
        settings,
        "Name",
        "URI",
    ];
}

export async function makeTGEArgs(
    tgeInfo: TGEInfoStruct,
    tokenInfo?: TokenInfoStruct
): Promise<TGEArgs> {
    return [
        tgeInfo,
        tokenInfo ?? {
            tokenType: 1,
            name: "",
            symbol: "",
            cap: 0,
            decimals: 0,
            description: "",
        },
        "URI2",
        "Let's do TGE once again",
        "hash",
    ];
}