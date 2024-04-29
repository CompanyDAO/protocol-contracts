# CompanyDAO Protocol Contracts

![thumb](https://raw.githubusercontent.com/CompanyDAO/protocol-contracts/main/images/main.jpg)

## INSTALLATION

Install project packages:

```sh
yarn install
```

Running Hardhat tests:

```sh
yarn hardhat test
```

Running code coverage tests:

```sh
yarn hardhat coverage
```

Deploy contracts:
```
yarn hardhat deploy --network goerli
```

### DEPLOYMENTS

Ethereum Mainnet

| Name | Address | Explorer |
| - | - | - |
| Service | `0x5860B6a91f7Af98f80A2510E287d5422fd43159E` | [link](https://etherscan.io/address/0x5860B6a91f7Af98f80A2510E287d5422fd43159E#code) |
| Registry | `0x82d24e8CEFd6D10aB99f3a4F30D8A87aF1A61a88` | [link](https://etherscan.io/address/0x82d24e8CEFd6D10aB99f3a4F30D8A87aF1A61a88#code) |

Polygon Mainnet

| Name | Address | Explorer |
| - | - | - |
| Service | `0x4159B8E9939d0da25f98bB887Beab89eB6BdE460` | [link](https://polygonscan.com/address/0x4159B8E9939d0da25f98bB887Beab89eB6BdE460#code) |
| Registry | `0x939BcC3d82ee006989387fBbc232C750F2295f4D` | [link](https://polygonscan.com/address/0x939BcC3d82ee006989387fBbc232C750F2295f4D#code) |




## DOCUMENTATION

### 1. Purpose of the product

This set of smart contracts is used for the on-chain purchase of pre-established (previously registered) companies and conducting their operational activities as DAOs. These contracts comprise all necessary tools for acquiring a legal entity, managing it by the holders of Governance tokens, and deploying additional contracts to ensure the full operation of the company on the Ethereum and Polygon networks.

![thumb](https://raw.githubusercontent.com/CompanyDAO/protocol-contracts/main/images/dao-pool.jpg)

#### 1.1 Company Acquisition

- One legal entity corresponds to one `Pool.sol` contract and one record in the `CompaniesRegistry.sol` contract. All of these are added by the Manager (the `COMPANIES_MANAGER` role in the Registry contract) through transactions containing the company's legal data in calldata;
- Using the `Service.sol` contract, a User can purchase a company in the specified `Jurisdiction` and of the specified `Entity Type`. If companies with the required parameters are available for purchase, the purchase transaction changes the owner of one of the appropriate pools to the buyer's address and sets the initial Governance and trademark settings. This is how an on-chain purchase is made for the gas coin (ETH, MATIC).
- For various reasons, purchases may be made off-chain, using the `Service.sol` contract by an address with the `SERVICE_MANAGER` role. In this case, the new owner of the pool becomes the account whose address was specified in the parameters of such a transaction.
- The acquired `Pool.sol` contract can be used by the owner on a limited basis until the Pool achieves **DAO** status. The owner can initiate a Governance Token Generation Event to distribute units of these tokens. If the funding reaches the level specified by the owner, the pool irreversibly becomes a **DAO**, fully legal and effectively operating in the specified jurisdiction.

#### 1.2 DAO Operation

- From the moment a pool attains **DAO** status, almost all actions on behalf of such a pool are carried out only as a result of voting.
- `Governance Settings`, stored in the Pool contract, determine who can create a Proposal in the same contract, what minimum number of participants and what proportion must vote for a decision to be considered adopted and a transaction to be executed.
- `Governance Settings` can be changed with a separate proposal.
- Only addresses that are delegatees can vote and create Proposals. For this, accounts holding units of the pool's Governance Token on their balance must `delegate` their voting power.
- However, by default, each purchase of Governance token units by an address during a TGE leads to delegation to itself, if it has not previously delegated its Voting Power to another address.
- **1 unit of Governance Token = 1 Vote**
- Issuing new units of Governance Token is only possible within a TGE.
- Starting with version 1.4 the new `Pool Manager` role is available to be granted to one account per pool to speed up and simplify the operating activities of the pools.

#### 1.3 Fees

The protocol provides for 3 types of fees:
- **Protocol Fee** - paid in gas coins at the time of pool purchase;
- **Partner Fee** - paid to the speicified beneficiary address in units of account in case of successful TGE;
- **Service Fee** - paid to the CompanyDAO Treasury in units of account  in case of successful TGE;
- _Protocol Token Fee_ -  deprecated and abolished.

##### Protocol Fee

- The `purchasePool` function is **payable**, i.e., when it's called to buy a pool, a 'Value' transfer occurs to the Service contract's address simultaneously with passing Governance Settings for configuring the purchased pool.
- Coins collected from user-invoked functions are held on the Service contract until the ADMIN initiates the call of the transferCollectedFees(address to) method to transfer all accumulated coins to the specified address.

##### Service and Partner Fees

- When the `Token Generation Event` ends with the status `Successful`, it becomes possible to launch the `transferFunds()` method in this contract.
- The collected units of account are split into 3 parts:
- - main funds to be transferred to  the pool contract (the main goal of the TGE) or to the specified `TGE Fund Receiver address` (available starting with v1.4) as the equivalent of issued and distributed tokens;
- - service fees to be transferred to the `ProtocolTreasury` address;
- - partner fees to be transferred to the specified by an initializer of the TGE as the marketing (or whatever) reward.
- The Treasury address and the size of the commission (percentage of the total  number of accepted tokens of unit of account) are specified by the **ADMIN** in the Service contract.
- The beneficiary address of Partner fee is specified before the launch of the TGE. 

_Even if there are token units with deferred minting for users (e.g., vesting program), the protocol commission is calculated from the total number of sold tokens immediately upon the launch of transferFunds()._


### 2. Role Model

The protocol has a complicated but balanced role model.

Since the `Service.sol` and `Registry.sol` contracts exist as single instances and influence all user and auxiliary contracts, they use the `OpenZeppelin Access Control` role model.

There can be an infinite number of pool contracts, so they use a simplified approach to define roles, which consists of using Ownable methods and a set of mappings. The role model of a pool with DAO status differs from the role model of a pool without such status.

#### 2.1 Role Model of the Service Contract
##### **ADMIN** (Open Zeppelin AC Role)

The main role of the entire ecosystem. The account that owns the contracts receives this role when the protocol is deployed.

The account that has received the **ADMIN** role can:
- update the implementations of upgradable contracts;
- set the size and address of the Treasury for Protocol Token Fee;
- transfer gas coins (ETH, MATIC), collected by the Service contract as a fee for buying pools, to any address;
- pause and unpause the entire protocol or a single pool;
- cancel Proposals, including those awaiting execution;
- perform the same actions as the SERVICE_MANAGER.

#### **SERVICE_MANAGER** (Open Zeppelin AC Role)

A secondary account for protocol administration, which can:
- set flags in the `Vesting.sol` and `TGE.sol` contracts that indicate that the pool has reached sufficient TVL to lift the lockup and vesting restrictions for a particular TVL;
- put marks on any invoice about its cancellation or payment.

_This role is intended for accounts managed by the protocol backend. Thus, the states of all contracts are kept up-to-date even due to triggering of temporal and off-chain triggers._

#### 2.2 Role Model of the Registry Contract
##### **COMPANIES_MANAGER** (Open Zeppelin AC Role)

- Accounts with this role are needed to add, edit, and delete entries about companies listed for sale.
- They are also needed to service already purchased companies.
- They are the ones who set and edit the commission size for purchasing a company.

#### 2.3 Role Model of Pool Contracts
##### **OWNER** (Open Zeppelin Ownable, custom logic)

- Before a company is purchased by a user and after the pool acquires `DAO` status, has no influence or special powers.
- This status is received by the account that successfully launched the `purchasePool` transaction or the address which was specified as the 'newowner' field when sending the `transferPurchasedPoolByService` transaction by an account with `SERVICE_MANAGER` role.
- The company owner can send funds from the Pool contract to other addresses, launch invoices, and `primary Governance Token Generation Events`.

##### **SECRETARY** (list of addresses)

- The list of addresses that have secretary powers is stored in each of the Pool contracts and can be changed with each change in Governance settings.
- This address can create proposals even without Governance Tokens on its balance, as well as create and cancel Invoices.

##### **EXECUTOR** (list of addresses)

- The list of addresses that have executor powers is stored in each of the Pool contracts and can be changed with each change in Governance settings.
- This address can initiate `execute` transactions for Pool on Proposals that have `Awaiting Execution` status.

#### **POOL MANAGER** 
- The account which is granted this role has the vote power that equals to the whole total supply of Governance tokens that is available at the moment of creating a ballot.

### 2.4 Role Model of TGE Contracts

#### **WHITELIST ADMIN**
- The account which is granted this role has the authority to adjust whitelist of TGE participants. This feature allows to manage the TGE processing in more precise way.

#### **FUND RECEIVER**
- This address is set to be the beneficiary of tokens issuance. It can be a 3rd-party treasury or a personal wallet. This feature increases the level of assets security.

### 2.5 Role Model of TSE Contracts

#### **SELLER**
- The address which is used to launch the TSE event has a special authority to stop the event or to edit the list of those who are allowed to partake the event.
- Also this account is supposed to be a beneficiary which receives the collected funds.

### 3. Public customer functions

#### Service.sol => purchasePool

This function initiates the user's interaction with the protocol. It allows specifying in the arguments the jurisdiction and the organizational form of the company. If there is at least one company available for sale with these parameters, the cost of such a company is deducted from the user's account, after which they become its owner.

```
function purchasePool(
        uint256 jurisdiction, // jurisdiction code
        uint256 entityType, // organizational type code
        string memory trademark, // string value
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings // set of Governance settings
    ) external payable
```
When purchasing a company, primary `GovernanceSettings` are also established, as well as the company's trademark.

_Please note that the trademark is currently an immutable parameter._

#### TGEFactory.sol => createPrimaryTGE

The owner of the pool, who has not yet obtained DAO status and does not have any other active TGE, can use this function to launch the TGE.

```
function createPrimaryTGE(
        address poolAddress, // contract address of the acquired pool
        IToken.TokenInfo memory tokenInfo, // structure with token parameters
        ITGE.TGEInfo memory tgeInfo, // structure with TGE parameters
        string memory metadataURI, // link to the metadata event
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_, // structure with Governance settings
        address[] memory secretary, // list of secretary addresses to be used instead of the existing ones
        address[] memory executor // list of executor addresses to be used instead of the existing ones
    ) external
```

As part of this transaction, a token candidate for Governance Token status will be created, and new lists of secretaries and executors and new Governance Settings can also be set.

#### TGE.sol => purchase

If the TGE is public or the user's account address is included in the whitelist of accounts admitted to the TGE, then the result of this function call will be the user purchasing tokens.

```
    function purchase(
        uint256 amount // number of tokens being purchased
    )
```

The user may not receive all or part of the tokens immediately if they are subject to a vesting program. Also, the user may receive tokens, but they will be allowed to manage them only after the lockup period ends.

But in any case, the information about their purchase will be stored in the contract.

#### TGE.sol => redeem

In case the specified `softcap` was not reached during the TGE, token purchasers can use this function to return their assets and burn unnecessary tokens.

```
  function redeem()
    external
    onlyState(State.Failed)
```

This function affects all the user's tokens in vesting (that is, they will be reimbursed after the first launch), as well as all tokens on the account balance.

#### TSE.sol => purchase

If the TSE is public or the user's account address is included in the whitelist of accounts admitted to the TSE, then the result of this function call will be the user purchasing tokens.

```
    function purchase(
        uint256 amount // number of tokens being purchased
    )
```

The user obtains the full amount of purchased tokens immediately which are non-refundable.


#### Vesting.sol => claim

When another stage of vesting comes to an end, the user can request a part of their tokens.

```
  function claim(address tge) external
```

When using such a function, the `totalSupply` of the token increases because tokens are not transferred but are minted on the user's address.

#### Pool.sol => propose

With this function, any account that meets the `Governance Settings` requirements can create a proposal for the pool.

```
    function propose(
        address proposer,
        uint256 proposeType,
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta
    ) 
```

For convenience, the types of proposals used in the current version have their constructors in the `CustomProposals.sol` contract.

#### Invoice.sol => payInvoice

With this function, an account can pay an invoice on-chain.

```
  function payInvoice(
          address pool,
          uint256 invoiceId
      ) external payable
```

For successful payment, it is necessary for the Invoice to be public or the user's address to be among the whitelist of Invoice addresses.

### 4. Features

#### 4.1 Proposal State

- Every proposal has markers for the voting start and end blocks. As soon as the blockchain height equals the voting end block, the proposal can no longer accept votes from accounts with voting rights.
- A decision **"for"** a proposal is only accepted if no less than `QuorumThreshold` percent of the total number of votes have voted, and if of these voters no less than `DecisionThreshold` voted "for".
- In all other cases, the decision is considered **"against"**.
- To save users' time, in cases where the advantage of one side is mathematically obvious, voting is terminated prematurely.
- A decision **"for"** leads to the proposal spending several blocks in waiting mode, during which the `ADMIN` of the protocol can still cancel execution.

![thumb](https://raw.githubusercontent.com/CompanyDAO/protocol-contracts/main/images/proposal-state.jpg)

All parameters that set the rules for conducting all voting in the pool are set using the interface:

```
    struct NewGovernanceSettings {
        uint256 proposalThreshold;
        uint256 quorumThreshold;
        uint256 decisionThreshold;
        uint256 votingDuration;
        uint256 transferValueForDelay;
        uint256[4] executionDelays;
        uint256 votingStartDelay;
    }
```

These parameters are stored in the Pool contract, as well as in each created proposal. Need a proposal with different Governance parameters? You first need to create a proposal to change these parameters using the old rules. Even after this, previously created proposals will maintain their behavior unchanged.

#### 4.2 Preference Tokens

Each pool can have only one Governance token contract. Units of this token are votes, with their help, one can directly influence the operational activities of the pool.

![thumb](https://raw.githubusercontent.com/CompanyDAO/protocol-contracts/main/images/tokens.jpg)

For all cases of measuring shares, collecting funds, or other cases of distributing any values not related to managing the Pool, `Preference Tokens` can be used.

- Two types `ERC20` and `ERC1155` (compatible with OpenSea);
- Distributed through TGE contracts, which are created only as a result of a proposal execution;
- Unlimited number of Preference token contracts for the pool;
- Unlimited number of ERC1155 collections for one Preference token;
- One TGE operates with only one Preference token (and only one ERC1155 token collection);
- The maximum emission size is set during the first TGE for each such contract (and at the first TGE for each of the ERC1155 collections).

Preference TGE may include a vesting and lockup program for the distributed tokens.

#### 4.3 Vesting and Lockup

Vesting and lockup can be set up for each TGE independently of other contracts. Vesting restrictions and lockup restrictions do not affect each other and are optional. They come into effect only after the user purchases tokens in the TGE and only on this volume of tokens (or part of it).

![thumb](https://raw.githubusercontent.com/CompanyDAO/protocol-contracts/main/images/lockup-vesting.jpg)

Vesting features:
- When purchasing, part of the tokens can be immediately minted to the buyer's balance (these token units are not vested, there can be 100% of them).
- The remaining part is not minted and exists virtually, in the form of an entry in the 'Vesting.sol' contract.
- When a period of `cliff` blocks ends, the user can claim `cliffShare` tokens.
- After the cliff period, `spans` periods of `spanDuration` blocks may pass. At the end of each of these periods, the user can claim `spanShare` tokens.
- If a condition for the pool to achieve TVL was entered when creating TGE for vesting, the vesting program does not take effect until the pool meets this condition (the `claimTVLReached` flag in the `Vesting.sol` contract).
- Tokens in vesting have not yet been minted, but they are taken into account when calculating the remaining Supply for the token. They cannot be sold, moved, used as votes or in any other way.

Lockup features:
- Lockup restricts the transfer of tokens.
- The restriction may apply to part or all of the tokens purchased during the TGE.
- Lockup has only one period of validity, after which the restriction is lifted.
- Lockup can also have a condition for the pool to achieve a certain TVL, without which even after the expiration of the lockup period the restriction is not lifted.
- Lockup parameters are stored in `TGE.sol`.

## AUDIT

SOLIDPROOF [ [website](https://solidproof.io/) ] [
[audit](https://github.com/solidproof/projects/tree/main/CompanyDAO) ] [ [report PDF](https://github.com/solidproof/projects/blob/main/CompanyDAO/SmartContract_Audit_Solidproof_CompanyDAO.pdf) ]

HASHEX [ [website](https://hashex.org/) ] [
[audit](https://github.com/HashEx/public_audits/tree/master/Company%20DAO) ] [ [report PDF](https://github.com/HashEx/public_audits/blob/master/Company%20DAO/Company%20DAO.pdf) ]

## REFERENCES

[Open-Zeppelin Upgradeable Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable)

[Open-Zeppelin Governance](https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/governance)

[Open-Zeppelin ERC20](https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC20)

[Open-Zeppelin Votes Upgradable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol)

[Open-Zeppelin Capped Upgradable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/ERC20CappedUpgradeable.sol)

[Open-Zeppelin ERC1155](https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155)
