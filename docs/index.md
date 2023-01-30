# Solidity API

## Pool

_These contracts are instances of on-chain implementations of user companies. The shareholders of the companies work with them, their addresses are used in the Registry contract as tags that allow obtaining additional legal information (before the purchase of the company by the client). They store legal data (after the purchase of the company by the client). Among other things, the contract is also the owner of the Token and TGE contracts.
There can be an unlimited number of such contracts, including for one company owner. The contract can be in three states: 1) the company was created by the administrator, a record of it is stored in the Registry, but the contract has not yet been deployed and does not have an owner (buyer) 2) the contract is deployed, the company has an owner, but there is not yet a successful (softcap primary TGE), in this state its owner has the exclusive right to recreate the TGE in case of their failure (only one TGE can be launched at the same time) 3) the primary TGE ended successfully, softcap is assembled - the company has received the status of DAO.    The owner no longer has any exclusive rights, all the actions of the company are carried out through the creation and execution of propousals after voting. In this status, the contract is also a treasury - it stores the company's values in the form of ETH and/or ERC20 tokens._

### trademark

```solidity
string trademark
```

_The company's trade mark, label, brand name. It also acts as the Name of all the Governance tokens created for this pool._

### companyInfo

```solidity
struct ICompaniesRegistry.CompanyInfo companyInfo
```

_When a buyer acquires a company, its record disappears from the Registry contract, but before that, the company's legal data is copied to this variable._

### tokens

```solidity
mapping(enum IToken.TokenType => address) tokens
```

_A list of tokens belonging to this pool. There can be only one valid Governance token and only one Preference token._

### lastProposalIdForAddress

```solidity
mapping(address => uint256) lastProposalIdForAddress
```

_last proposal id for address. This method returns the proposal Id for the last proposal created by the specified address._

### Received

```solidity
event Received(uint256 amount)
```

_Special event that is released when the receive method is used. Thus, it is possible to make the receipt of ETH by the contract more noticeable._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | Amount of received ETH |

### onlyService

```solidity
modifier onlyService()
```

_Is executed when the main contract is applied. It is used to transfer control of Registry and deployable user contracts for the final configuration of the company._

### onlyServiceAdmin

```solidity
modifier onlyServiceAdmin()
```

### onlyPool

```solidity
modifier onlyPool()
```

### onlyExecutor

```solidity
modifier onlyExecutor(uint256 proposalId)
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address owner_, string trademark_, struct IGovernanceSettings.NewGovernanceSettings governanceSettings_, struct ICompaniesRegistry.CompanyInfo companyInfo_) external
```

_Initialization of a new pool and placement of user settings and data (including legal ones) in it_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner_ | address | Pool owner |
| trademark_ | string | Trademark |
| governanceSettings_ | struct IGovernanceSettings.NewGovernanceSettings | GovernanceSettings_ |
| companyInfo_ | struct ICompaniesRegistry.CompanyInfo | Company info |

### receive

```solidity
receive() external payable
```

_Method for receiving an Ethereum contract that issues an event._

### castVote

```solidity
function castVote(uint256 proposalId, bool support) external
```

_With this method, the owner of the Governance token of the pool can vote for one of the active propo-nodes, specifying its number and the value of the vote (for or against). One user can vote only once for one proposal with all the available balance that is in delegation at once._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Pool proposal ID |
| support | bool | Against or for |

### setToken

```solidity
function setToken(address token_, enum IToken.TokenType tokenType_) external
```

_Adding a new entry about the deployed token contract to the list of tokens related to the pool._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token_ | address | Token address |
| tokenType_ | enum IToken.TokenType | Token type |

### executeProposal

```solidity
function executeProposal(uint256 proposalId) external
```

_Execute proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### cancelProposal

```solidity
function cancelProposal(uint256 proposalId) external
```

_Cancel proposal, callable only by Service_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### pause

```solidity
function pause() public
```

_Pause pool and corresponding TGEs and Tokens_

### unpause

```solidity
function unpause() public
```

_Unpause pool and corresponding TGEs and Tokens_

### isDAO

```solidity
function isDAO() external view returns (bool)
```

_Getter showing whether this company has received the status of a DAO as a result of the successful completion of the primary TGE (that is, launched by the owner of the company and with the creation of a new Governance token). After receiving the true status, it is not transferred back. This getter is responsible for the basic logic of starting a contract as managed by token holders._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is any governance TGE successful |

### owner

```solidity
function owner() public view returns (address)
```

_Return pool owner_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Owner address |

### getToken

```solidity
function getToken(enum IToken.TokenType tokenType) external view returns (contract IToken)
```

_This getter is needed in order to return a Token contract address depending on the type of token requested (Governance or Preference)._

### _afterProposalCreated

```solidity
function _afterProposalCreated(uint256 proposalId) internal
```

_Hook called after proposal creation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### _getCurrentVotes

```solidity
function _getCurrentVotes(address account) internal view returns (uint256)
```

_Function that gets amount of votes for given account_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Account's address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Amount of votes |

### _getCurrentTotalVotes

```solidity
function _getCurrentTotalVotes() internal view returns (uint256)
```

_This getter returns the maximum number of votes distributed among the holders of the Governance token of the pool, which is equal to the sum of the balances of all addresses, except TGE, holding tokens in vesting, where they cannot have voting power. The getter's answer is valid for the current block._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Amount of votes |

### _getPastVotes

```solidity
function _getPastVotes(address account, uint256 blockNumber) internal view returns (uint256)
```

_Function that gets amount of votes for given account at given block_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Account's address |
| blockNumber | uint256 | Block number |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Account's votes at given block |

### paused

```solidity
function paused() public view returns (bool)
```

_Return pool paused status_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is pool paused |

### _setLastProposalIdForAddress

```solidity
function _setLastProposalIdForAddress(address proposer, uint256 proposalId) internal
```

_This function stores the proposal id for the last proposal created by the proposer address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposer | address | Proposer's address |
| proposalId | uint256 | Proposal id |

## Registry

_The repository of all user and business entities created by the protocol: companies to be implemented, contracts to be deployed, proposal created by shareholders._

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize() public
```

_Initializer_

## Service

_The main service contract through which the administrator manages the project, assigns roles to individual wallets, changes service commissions, and also through which the user creates pool contracts. Exists in a single copy._

### DENOM

```solidity
uint256 DENOM
```

Denominator for shares (such as thresholds)

### ADMIN_ROLE

```solidity
bytes32 ADMIN_ROLE
```

Default admin  role

### SERVICE_MANAGER_ROLE

```solidity
bytes32 SERVICE_MANAGER_ROLE
```

User manager role

### WHITELISTED_USER_ROLE

```solidity
bytes32 WHITELISTED_USER_ROLE
```

User role

### EXECUTOR_ROLE

```solidity
bytes32 EXECUTOR_ROLE
```

Executor role

### registry

```solidity
contract IRegistry registry
```

_Registry address_

### poolBeacon

```solidity
address poolBeacon
```

_Pool beacon_

### tokenBeacon

```solidity
address tokenBeacon
```

_Token beacon_

### tgeBeacon

```solidity
address tgeBeacon
```

_TGE beacon_

### protocolTreasury

```solidity
address protocolTreasury
```

_There gets 0.1% (the value can be changed by the admin) of all Governance tokens from successful TGE_

### protocolTokenFee

```solidity
uint256 protocolTokenFee
```

_protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000_

### PoolCreated

```solidity
event PoolCreated(address pool, address token, address tge)
```

_Event emitted on pool creation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| token | address | Pool token address |
| tge | address | Pool primary TGE address |

### SecondaryTGECreated

```solidity
event SecondaryTGECreated(address pool, address tge, address token)
```

_Event emitted on creation of secondary TGE._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| tge | address | Secondary TGE address |
| token | address | Preference token address |

### ProtocolTreasuryChanged

```solidity
event ProtocolTreasuryChanged(address protocolTreasury)
```

_Event emitted on protocol treasury change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protocolTreasury | address | Protocol treasury address |

### ProtocolTokenFeeChanged

```solidity
event ProtocolTokenFeeChanged(uint256 protocolTokenFee)
```

_Event emitted on protocol token fee change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protocolTokenFee | uint256 | Protocol token fee |

### FeesTransferred

```solidity
event FeesTransferred(address to, uint256 amount)
```

_Event emitted on transferring collected fees._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Transfer recepient |
| amount | uint256 | Amount of transferred ETH |

### ProposalCancelled

```solidity
event ProposalCancelled(address pool, uint256 proposalId)
```

_Event emitted on proposal cacellation by service owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| proposalId | uint256 | Pool local proposal id |

### onlyPool

```solidity
modifier onlyPool()
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(contract IRegistry registry_, address poolBeacon_, address tokenBeacon_, address tgeBeacon_, uint256 protocolTokenFee_) external
```

_Constructor function, can only be called once_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| registry_ | contract IRegistry | Registry address |
| poolBeacon_ | address | Pool beacon |
| tokenBeacon_ | address | Governance token beacon |
| tgeBeacon_ | address | TGE beacon |
| protocolTokenFee_ | uint256 | Protocol token fee |

### createPool

```solidity
function createPool(contract IPool pool, uint256 tokenCap, string tokenSymbol, struct ITGE.TGEInfo tgeInfo, uint256 jurisdiction, uint256 entityType, struct IGovernanceSettings.NewGovernanceSettings governanceSettings, string trademark, string metadataURI) external payable
```

_Method for purchasing a pool by the user. Among the data submitted for input, there are jurisdiction and Entity Type, which are used as keys to, firstly, find out if there is a company available for acquisition with such parameters among the Registry records, and secondly, to get the data of such a company if it exists, save them to the deployed pool contract, while recording the company is removed from the Registry. This action is only available to users who are on the global white list of addresses allowed before the acquisition of companies. At the same time, the Governance token contract and the TGE contract are deployed for its implementation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool address. If not address(0) - creates new token and new primary TGE for an existing pool. |
| tokenCap | uint256 | Pool token cap |
| tokenSymbol | string | Pool token symbol |
| tgeInfo | struct ITGE.TGEInfo | Pool TGE parameters |
| jurisdiction | uint256 | Pool jurisdiction |
| entityType | uint256 | Company entity type |
| governanceSettings | struct IGovernanceSettings.NewGovernanceSettings | Governance setting parameters |
| trademark | string | Pool trademark |
| metadataURI | string | Metadata URI |

### createSecondaryTGE

```solidity
function createSecondaryTGE(struct ITGE.TGEInfo tgeInfo, struct IToken.TokenInfo tokenInfo, string metadataURI) external
```

_Method for launching secondary TGE (i.e. without reissuing the token) for Governance tokens, as well as for creating and launching TGE for Preference tokens. It can be started only as a result of the execution of the proposal on behalf of the pool._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tgeInfo | struct ITGE.TGEInfo | TGE parameters |
| tokenInfo | struct IToken.TokenInfo | Token parameters |
| metadataURI | string | Metadata URI |

### addProposal

```solidity
function addProposal(uint256 proposalId) external
```

_Add proposal to directory_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### addEvent

```solidity
function addEvent(enum IRecordsRegistry.EventType eventType, uint256 proposalId, string metaHash) external
```

_Add event to directory_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| eventType | enum IRecordsRegistry.EventType | Event type |
| proposalId | uint256 | Proposal ID |
| metaHash | string | Hash value of event metadata |

### transferCollectedFees

```solidity
function transferCollectedFees(address to) external
```

_Transfer collected createPool protocol fees_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Transfer recipient |

### setProtocolTreasury

```solidity
function setProtocolTreasury(address _protocolTreasury) public
```

_Assignment of the address to which the commission will be collected in the form of Governance tokens issued under successful TGE_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _protocolTreasury | address | Protocol treasury address |

### setProtocolTokenFee

```solidity
function setProtocolTokenFee(uint256 _protocolTokenFee) public
```

_Set protocol token fee_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _protocolTokenFee | uint256 | protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000. |

### cancelProposal

```solidity
function cancelProposal(address pool, uint256 proposalId) public
```

_Cancel pool's proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | pool |
| proposalId | uint256 | proposalId |

### pause

```solidity
function pause() public
```

_Pause service_

### unpause

```solidity
function unpause() public
```

_Unpause service_

### getMinSoftCap

```solidity
function getMinSoftCap() public view returns (uint256)
```

_Calculate minimum soft cap for token fee mechanism to work_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | softCap minimum soft cap |

### getProtocolTokenFee

```solidity
function getProtocolTokenFee(uint256 amount) public view returns (uint256)
```

_Сalculates protocol token fee for given token amount_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | Token amount |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | tokenFee |

### getMaxHardCap

```solidity
function getMaxHardCap(address _pool) public view returns (uint256)
```

_Return max hard cap accounting for protocol token fee_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pool | address | pool to calculate hard cap against |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Maximum hard cap |

### validateTGEInfo

```solidity
function validateTGEInfo(struct ITGE.TGEInfo info, uint256 cap, uint256 totalSupply, enum IToken.TokenType tokenType) external view
```

_Service function that is used to check the correctness of TGE parameters (for the absence of conflicts between parameters)_

### getPoolAddress

```solidity
function getPoolAddress(struct ICompaniesRegistry.CompanyInfo info) external view returns (address)
```

_Get's create2 address for pool_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| info | struct ICompaniesRegistry.CompanyInfo | Company info |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Pool contract address |

### _getCreate2Data

```solidity
function _getCreate2Data(struct ICompaniesRegistry.CompanyInfo info) internal view returns (bytes32 salt, bytes deployBytecode)
```

_Gets data for pool's create2_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| info | struct ICompaniesRegistry.CompanyInfo | Company info |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| salt | bytes32 | Create2 salt |
| deployBytecode | bytes | Deployed bytecode |

### _createPool

```solidity
function _createPool(struct ICompaniesRegistry.CompanyInfo info) internal returns (contract IPool pool)
```

_Create pool contract and initialize it_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool contract |

### _createToken

```solidity
function _createToken() internal returns (contract IToken token)
```

_Create token contract_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | contract IToken | Token contract |

### _createTGE

```solidity
function _createTGE(string metadataURI, address pool) internal returns (contract ITGE tge)
```

_Create TGE contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| metadataURI | string | TGE metadata URI |
| pool | address | Pool address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | contract ITGE | TGE contract |

## TGE

### DENOM

```solidity
uint256 DENOM
```

Denominator for shares (such as thresholds)

### token

```solidity
contract IToken token
```

_Pool's ERC20 token_

### info

```solidity
struct ITGE.TGEInfo info
```

_TGE info struct_

### _isUserWhitelisted

```solidity
mapping(address => bool) _isUserWhitelisted
```

_Mapping of user's address to whitelist status_

### createdAt

```solidity
uint256 createdAt
```

_Block of TGE's creation_

### purchaseOf

```solidity
mapping(address => uint256) purchaseOf
```

_Mapping of an address to total amount of tokens purchased during TGE_

### totalPurchased

```solidity
uint256 totalPurchased
```

_Total amount of tokens purchased during TGE_

### vestingTVLReached

```solidity
bool vestingTVLReached
```

_Is vesting TVL reached. Users can claim their tokens only if vesting TVL was reached._

### lockupTVLReached

```solidity
bool lockupTVLReached
```

_Is lockup TVL reached. Users can claim their tokens only if lockup TVL was reached._

### vestedBalanceOf

```solidity
mapping(address => uint256) vestedBalanceOf
```

_Mapping of addresses to total amounts of tokens vested_

### totalVested

```solidity
uint256 totalVested
```

_Total amount of tokens vested_

### protocolFee

```solidity
uint256 protocolFee
```

_Protocol fee_

### isProtocolTokenFeeClaimed

```solidity
bool isProtocolTokenFeeClaimed
```

_Protocol token fee is a percentage of tokens sold during TGE. Returns true if fee was claimed by the governing DAO._

### Purchased

```solidity
event Purchased(address buyer, uint256 amount)
```

_Event emitted on token purchase._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| buyer | address | buyer |
| amount | uint256 | amount of tokens |

### ProtocolTokenFeeClaimed

```solidity
event ProtocolTokenFeeClaimed(address token, uint256 tokenFee)
```

_Event emitted on claim of protocol token fee._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | token |
| tokenFee | uint256 | amount of tokens |

### Redeemed

```solidity
event Redeemed(address account, uint256 refundValue)
```

_Event emitted on token claim._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Redeemer address |
| refundValue | uint256 | Refund value |

### Claimed

```solidity
event Claimed(address account, uint256 amount)
```

_Event emitted on token claim._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Claimer address |
| amount | uint256 | Amount of claimed tokens |

### FundsTransferred

```solidity
event FundsTransferred(uint256 amount)
```

_Event emitted on transfer funds to pool._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | Amount of transferred tokens/ETH |

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(contract IToken _token, struct ITGE.TGEInfo _info, uint256 protocolFee_) external
```

_Constructor function, can only be called once_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | contract IToken | pool's token |
| _info | struct ITGE.TGEInfo | TGE parameters |
| protocolFee_ | uint256 |  |

### purchase

```solidity
function purchase(uint256 amount) external payable
```

_Purchase pool's tokens during TGE_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | amount of tokens in wei (10**18 = 1 token) |

### redeem

```solidity
function redeem() external
```

_Return purchased tokens and get back tokens paid_

### claim

```solidity
function claim() external
```

_Claim vested tokens_

### setVestingTVLReached

```solidity
function setVestingTVLReached() external
```

### setLockupTVLReached

```solidity
function setLockupTVLReached() external
```

### transferFunds

```solidity
function transferFunds() external
```

_Transfer proceeds from TGE to pool's treasury. Claim protocol fee._

### _claimProtocolTokenFee

```solidity
function _claimProtocolTokenFee() private
```

_Transfers protocol token fee in form of pool's governance tokens to protocol treasury_

### maxPurchaseOf

```solidity
function maxPurchaseOf(address account) public view returns (uint256)
```

_How many tokens an address can purchase._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Amount of tokens |

### state

```solidity
function state() public view returns (enum ITGE.State)
```

_Returns TGE's state._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum ITGE.State | State |

### claimAvailable

```solidity
function claimAvailable() public view returns (bool)
```

_Is claim available for vested tokens._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is claim available |

### transferUnlocked

```solidity
function transferUnlocked() public view returns (bool)
```

_Is transfer available for lockup preference tokens._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is transfer available |

### lockedBalanceOf

```solidity
function lockedBalanceOf(address account) external view returns (uint256)
```

_Locked balance of account in current TGE_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Account address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Locked balance |

### getTotalPurchasedValue

```solidity
function getTotalPurchasedValue() public view returns (uint256)
```

_Get total value of all purchased tokens_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total value |

### getTotalVestedValue

```solidity
function getTotalVestedValue() public view returns (uint256)
```

_Get total value of all vestied tokens_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total value |

### getUserWhitelist

```solidity
function getUserWhitelist() external view returns (address[])
```

_Get userwhitelist info_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | User whitelist |

### isUserWhitelisted

```solidity
function isUserWhitelisted(address account) public view returns (bool)
```

_Checks if user is whitelisted_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | User address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Flag if user if whitelisted |

### onlyState

```solidity
modifier onlyState(enum ITGE.State state_)
```

### onlyWhitelistedUser

```solidity
modifier onlyWhitelistedUser()
```

### onlyManager

```solidity
modifier onlyManager()
```

### whenPoolNotPaused

```solidity
modifier whenPoolNotPaused()
```

## Token

_Company (Pool) Token_

### service

```solidity
contract IService service
```

_Service address_

### pool

```solidity
address pool
```

_Pool address_

### tokenType

```solidity
enum IToken.TokenType tokenType
```

_Token type_

### description

```solidity
string description
```

_Preference token description, allows up to 5000 characters, for others - ""_

### tgeList

```solidity
address[] tgeList
```

_List of all TGEs_

### _decimals

```solidity
uint8 _decimals
```

_Token decimals_

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address pool_, struct IToken.TokenInfo info, address primaryTGE_) external
```

_Constructor function, can only be called once_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool_ | address | Pool |
| info | struct IToken.TokenInfo | Token info struct |
| primaryTGE_ | address | Primary tge address |

### mint

```solidity
function mint(address to, uint256 amount) external
```

_Mint token_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Recipient |
| amount | uint256 | Amount of tokens |

### burn

```solidity
function burn(address from, uint256 amount) external
```

_Burn token_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | Target |
| amount | uint256 | Amount of tokens |

### addTGE

```solidity
function addTGE(address tge) external
```

_Add TGE to TGE archive list_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE address |

### decimals

```solidity
function decimals() public view returns (uint8)
```

_Return decimals_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint8 | Decimals |

### cap

```solidity
function cap() public view returns (uint256)
```

_Return cap_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Cap |

### symbol

```solidity
function symbol() public view returns (string)
```

_Return cap_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | Cap |

### unlockedBalanceOf

```solidity
function unlockedBalanceOf(address account) public view returns (uint256)
```

_Returns unlocked balance of account_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Account address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Unlocked balance of account |

### isPrimaryTGESuccessful

```solidity
function isPrimaryTGESuccessful() external view returns (bool)
```

_Return if pool had a successful TGE_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is any TGE successful |

### getTGEList

```solidity
function getTGEList() external view returns (address[])
```

_Return list of pool's TGEs_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | TGE list |

### lastTGE

```solidity
function lastTGE() external view returns (address)
```

_Return list of pool's TGEs_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | TGE list |

### getTotalTGEVestedTokens

```solidity
function getTotalTGEVestedTokens() public view returns (uint256)
```

_Return amount of tokens currently vested in TGE vesting contract(s)_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total vesting tokens |

### _transfer

```solidity
function _transfer(address from, address to, uint256 amount) internal
```

_Transfer tokens from a given user.
Check to make sure that transfer amount is less or equal
to least amount of unlocked tokens for any proposal that user might have voted for._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | User address |
| to | address | Recipient address |
| amount | uint256 | Amount of tokens |

### _afterTokenTransfer

```solidity
function _afterTokenTransfer(address from, address to, uint256 amount) internal
```

_Hook that is called after any transfer of tokens. This includes
minting and burning._

### _mint

```solidity
function _mint(address account, uint256 amount) internal
```

_Creates `amount` tokens and assigns them to `account`, increasing
the total supply._

### _burn

```solidity
function _burn(address account, uint256 amount) internal
```

_Destroys `amount` tokens from `account`, reducing the
total supply._

### onlyPool

```solidity
modifier onlyPool()
```

### onlyService

```solidity
modifier onlyService()
```

### onlyTGE

```solidity
modifier onlyTGE()
```

### whenPoolNotPaused

```solidity
modifier whenPoolNotPaused()
```

## GovernanceSettings

### DENOM

```solidity
uint256 DENOM
```

Denominator for shares (such as thresholds)

### MAX_BASE_EXECUTION_DELAY

```solidity
uint256 MAX_BASE_EXECUTION_DELAY
```

Max base execution delay (as blocks)

### proposalThreshold

```solidity
uint256 proposalThreshold
```

Threshold of votes required to propose

### quorumThreshold

```solidity
uint256 quorumThreshold
```

Threshold of votes required to reach quorum

### decisionThreshold

```solidity
uint256 decisionThreshold
```

Threshold of for votes required for proposal to succeed

### votingDuration

```solidity
uint256 votingDuration
```

Duration of proposal voting (as blocks)

### transferValueForDelay

```solidity
uint256 transferValueForDelay
```

Minimal transfer value to trigger delay

### executionDelays

```solidity
mapping(enum IRecordsRegistry.EventType => uint256) executionDelays
```

Delays for proposal types

### __gap

```solidity
uint256[50] __gap
```

Storage gap (for future upgrades)

### GovernanceSettingsSet

```solidity
event GovernanceSettingsSet(uint256 proposalThreshold_, uint256 quorumThreshold_, uint256 decisionThreshold_, uint256 votingDuration_, uint256 transferValueForDelay_, uint256[4] executionDelays_)
```

Event emitted when governance settings are set

### setGovernanceSettings

```solidity
function setGovernanceSettings(struct IGovernanceSettings.NewGovernanceSettings settings) external
```

Updates governance settings

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| settings | struct IGovernanceSettings.NewGovernanceSettings | New governance settings |

### _setGovernanceSettings

```solidity
function _setGovernanceSettings(struct IGovernanceSettings.NewGovernanceSettings settings) internal
```

Updates governance settings

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| settings | struct IGovernanceSettings.NewGovernanceSettings | New governance settings |

### _validateGovernanceSettings

```solidity
function _validateGovernanceSettings(struct IGovernanceSettings.NewGovernanceSettings settings) internal pure
```

Validates governance settings

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| settings | struct IGovernanceSettings.NewGovernanceSettings | New governance settings |

## Governor

_Proposal module for Pool's Governance Token_

### DENOM

```solidity
uint256 DENOM
```

Denominator for shares (such as thresholds)

### ProposalState

```solidity
enum ProposalState {
  None,
  Active,
  Failed,
  Delayed,
  AwaitingExecution,
  Executed,
  Cancelled
}
```

### ProposalCoreData

```solidity
struct ProposalCoreData {
  address[] targets;
  uint256[] values;
  bytes[] callDatas;
  uint256 quorumThreshold;
  uint256 decisionThreshold;
  uint256 executionDelay;
}
```

### ProposalVotingData

```solidity
struct ProposalVotingData {
  uint256 startBlock;
  uint256 endBlock;
  uint256 availableVotes;
  uint256 forVotes;
  uint256 againstVotes;
  enum Governor.ProposalState executionState;
}
```

### ProposalMetaData

```solidity
struct ProposalMetaData {
  enum IRecordsRegistry.EventType proposalType;
  string description;
  string metaHash;
}
```

### Proposal

```solidity
struct Proposal {
  struct Governor.ProposalCoreData core;
  struct Governor.ProposalVotingData vote;
  struct Governor.ProposalMetaData meta;
}
```

### proposals

```solidity
mapping(uint256 => struct Governor.Proposal) proposals
```

_Proposals_

### Ballot

```solidity
enum Ballot {
  None,
  Against,
  For
}
```

### ballots

```solidity
mapping(address => mapping(uint256 => enum Governor.Ballot)) ballots
```

_Voter's ballots_

### lastProposalId

```solidity
uint256 lastProposalId
```

_Last proposal ID_

### ProposalCreated

```solidity
event ProposalCreated(uint256 proposalId, struct Governor.ProposalCoreData core, struct Governor.ProposalMetaData meta)
```

_Event emitted on proposal creation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |
| core | struct Governor.ProposalCoreData | Proposal core data |
| meta | struct Governor.ProposalMetaData | Proposal meta data |

### VoteCast

```solidity
event VoteCast(address voter, uint256 proposalId, uint256 votes, enum Governor.Ballot ballot)
```

_Event emitted on proposal vote cast_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| voter | address | Voter address |
| proposalId | uint256 | Proposal ID |
| votes | uint256 | Amount of votes |
| ballot | enum Governor.Ballot | Ballot (against or for) |

### ProposalExecuted

```solidity
event ProposalExecuted(uint256 proposalId)
```

_Event emitted on proposal execution_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### ProposalCancelled

```solidity
event ProposalCancelled(uint256 proposalId)
```

_Event emitted on proposal cancellation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### proposalState

```solidity
function proposalState(uint256 proposalId) public view returns (enum Governor.ProposalState)
```

_A method that allows you to find out the result of voting for a specific proposal in the pool. Usually, the promotion is considered successful (the decision is "for") if during the time allotted for voting, at least Quorum percent (including DENOM) of the total number of tokens in circulation (issued and not blocked) and Decision Threshold percent (including DENOM) of votes "for" of the total number of collected votes are collected._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum Governor.ProposalState | ProposalState |

### getBallot

```solidity
function getBallot(address account, uint256 proposalId) public view returns (enum Governor.Ballot ballot, uint256 votes)
```

_Return voting result for a given account and proposal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Account address |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| ballot | enum Governor.Ballot | Vote type |
| votes | uint256 | Number of votes cast |

### _propose

```solidity
function _propose(struct Governor.ProposalCoreData core, struct Governor.ProposalMetaData meta, uint256 votingDuration) internal returns (uint256 proposalId)
```

_Creating a proposal and assigning it a unique identifier to store in the list of proposals in the Governor contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| core | struct Governor.ProposalCoreData | Proposal core data |
| meta | struct Governor.ProposalMetaData | Proposal meta data |
| votingDuration | uint256 | Voting duration in blocks |

### _castVote

```solidity
function _castVote(uint256 proposalId, bool support) internal
```

_Method for voting addresses for or against any proposal. It can be used only for active promo sites, and the probability of an early end of voting is taken into account. After each call of this method, an assessment is made of whether the remaining free votes can change the course of voting, if not, then voting ends ahead of schedule._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |
| support | bool | Against or for |

### _executeProposal

```solidity
function _executeProposal(uint256 proposalId, contract IService service) internal
```

_Performance of the proposal with checking its status. Only the Awaiting Execution of the proposals can be executed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |
| service | contract IService | Service address |

### _cancelProposal

```solidity
function _cancelProposal(uint256 proposalId) internal
```

_The substitution of proposals, both active and those that have a positive voting result, but have not yet been executed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### _checkProposalVotingEarlyEnd

```solidity
function _checkProposalVotingEarlyEnd(uint256 proposalId) internal
```

_The method checks whether it is possible to end the voting early with the result fixed. If a quorum was reached and so many votes were cast in favor that even if all other available votes were cast against, or if so many votes were cast against that it could not affect the result of the vote, this getter will return_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### shareReached

```solidity
function shareReached(uint256 amount, uint256 total, uint256 share) internal pure returns (bool)
```

_Checks if `amount` divided by `total` exceeds `share`_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | Amount numerator |
| total | uint256 | Amount denominator |
| share | uint256 | Share numerator |

### _afterProposalCreated

```solidity
function _afterProposalCreated(uint256 proposalId) internal virtual
```

_Hook called after proposal creation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### _getCurrentTotalVotes

```solidity
function _getCurrentTotalVotes() internal view virtual returns (uint256)
```

_Function that gets total amount of votes_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total amount of votes |

### _getPastVotes

```solidity
function _getPastVotes(address account, uint256 blockNumber) internal view virtual returns (uint256)
```

_Function that gets amount of votes for given account at given block_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Account's address |
| blockNumber | uint256 | Block number |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Account's votes at given block |

### _setLastProposalIdForAddress

```solidity
function _setLastProposalIdForAddress(address proposer, uint256 proposalId) internal virtual
```

_Function that gets amount of votes for given account at given block_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposer | address | Proposer's address |
| proposalId | uint256 | Proposal id |

## GovernorProposals

### service

```solidity
contract IService service
```

_Service address_

### __gap

```solidity
uint256[50] __gap
```

Storage gap (for future upgrades)

### onlyValidProposer

```solidity
modifier onlyValidProposer()
```

### __GovernorProposals_init

```solidity
function __GovernorProposals_init(contract IService service_) internal
```

### proposeTransfer

```solidity
function proposeTransfer(address asset, address[] recipients, uint256[] amounts, string description, string metaHash) external returns (uint256 proposalId)
```

_Propose transfer of assets_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| asset | address | Asset to transfer (address(0) for ETH transfers) |
| recipients | address[] | Transfer recipients |
| amounts | uint256[] | Transfer amounts |
| description | string | Proposal description |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal's ID |

### proposeTGE

```solidity
function proposeTGE(struct ITGE.TGEInfo tgeInfo, struct IToken.TokenInfo tokenInfo, string metadataURI, string description, string metaHash) external returns (uint256 proposalId)
```

_Propose new TGE_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tgeInfo | struct ITGE.TGEInfo | TGE parameters |
| tokenInfo | struct IToken.TokenInfo | Token parameters |
| metadataURI | string | TGE metadata URI |
| description | string | Proposal description |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal's ID |

### proposeGovernanceSettings

```solidity
function proposeGovernanceSettings(struct IGovernanceSettings.NewGovernanceSettings settings, string description, string metaHash) external returns (uint256 proposalId)
```

Propose new governance settings

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| settings | struct IGovernanceSettings.NewGovernanceSettings | New governance settings |
| description | string | Proposal description |
| metaHash | string | Hash value of proposal metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Created proposal's ID |

### _getDelay

```solidity
function _getDelay(enum IRecordsRegistry.EventType proposalType) internal view returns (uint256)
```

Gets execution delay for given proposal type

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalType | enum IRecordsRegistry.EventType | Proposal type |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Execution delay |

### _getCurrentVotes

```solidity
function _getCurrentVotes(address account) internal view virtual returns (uint256)
```

_Function that gets amount of votes for given account_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Account's address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Amount of votes |

## IPool

### initialize

```solidity
function initialize(address owner_, string trademark_, struct IGovernanceSettings.NewGovernanceSettings governanceSettings_, struct ICompaniesRegistry.CompanyInfo companyInfo_) external
```

### setToken

```solidity
function setToken(address token_, enum IToken.TokenType tokenType_) external
```

### cancelProposal

```solidity
function cancelProposal(uint256 proposalId) external
```

### owner

```solidity
function owner() external view returns (address)
```

### isDAO

```solidity
function isDAO() external view returns (bool)
```

### trademark

```solidity
function trademark() external view returns (string)
```

### paused

```solidity
function paused() external view returns (bool)
```

### getToken

```solidity
function getToken(enum IToken.TokenType tokenType_) external view returns (contract IToken)
```

## IService

### ADMIN_ROLE

```solidity
function ADMIN_ROLE() external view returns (bytes32)
```

### WHITELISTED_USER_ROLE

```solidity
function WHITELISTED_USER_ROLE() external view returns (bytes32)
```

### SERVICE_MANAGER_ROLE

```solidity
function SERVICE_MANAGER_ROLE() external view returns (bytes32)
```

### EXECUTOR_ROLE

```solidity
function EXECUTOR_ROLE() external view returns (bytes32)
```

### createSecondaryTGE

```solidity
function createSecondaryTGE(struct ITGE.TGEInfo tgeInfo, struct IToken.TokenInfo tokenInfo, string metadataURI) external
```

### addProposal

```solidity
function addProposal(uint256 proposalId) external
```

### addEvent

```solidity
function addEvent(enum IRecordsRegistry.EventType eventType, uint256 proposalId, string metaHash) external
```

### registry

```solidity
function registry() external view returns (contract IRegistry)
```

### protocolTreasury

```solidity
function protocolTreasury() external view returns (address)
```

### protocolTokenFee

```solidity
function protocolTokenFee() external view returns (uint256)
```

### getMinSoftCap

```solidity
function getMinSoftCap() external view returns (uint256)
```

### getProtocolTokenFee

```solidity
function getProtocolTokenFee(uint256 amount) external view returns (uint256)
```

### poolBeacon

```solidity
function poolBeacon() external view returns (address)
```

### tgeBeacon

```solidity
function tgeBeacon() external view returns (address)
```

### validateTGEInfo

```solidity
function validateTGEInfo(struct ITGE.TGEInfo info, uint256 cap, uint256 totalSupply, enum IToken.TokenType tokenType) external view
```

### getPoolAddress

```solidity
function getPoolAddress(struct ICompaniesRegistry.CompanyInfo info) external view returns (address)
```

## ITGE

### TGEInfo

```solidity
struct TGEInfo {
  uint256 price;
  uint256 hardcap;
  uint256 softcap;
  uint256 minPurchase;
  uint256 maxPurchase;
  uint256 vestingPercent;
  uint256 vestingDuration;
  uint256 vestingTVL;
  uint256 duration;
  address[] userWhitelist;
  address unitOfAccount;
  uint256 lockupDuration;
  uint256 lockupTVL;
}
```

### initialize

```solidity
function initialize(contract IToken token_, struct ITGE.TGEInfo info, uint256 protocolFee) external
```

### State

```solidity
enum State {
  Active,
  Failed,
  Successful
}
```

### state

```solidity
function state() external view returns (enum ITGE.State)
```

### transferUnlocked

```solidity
function transferUnlocked() external view returns (bool)
```

### totalVested

```solidity
function totalVested() external view returns (uint256)
```

### purchaseOf

```solidity
function purchaseOf(address user) external view returns (uint256)
```

### vestedBalanceOf

```solidity
function vestedBalanceOf(address user) external view returns (uint256)
```

### lockedBalanceOf

```solidity
function lockedBalanceOf(address account) external view returns (uint256)
```

## IToken

### TokenInfo

```solidity
struct TokenInfo {
  enum IToken.TokenType tokenType;
  string name;
  string symbol;
  string description;
  uint256 cap;
  uint8 decimals;
}
```

### TokenType

```solidity
enum TokenType {
  None,
  Governance,
  Preference
}
```

### initialize

```solidity
function initialize(address pool_, struct IToken.TokenInfo info, address primaryTGE_) external
```

### mint

```solidity
function mint(address to, uint256 amount) external
```

### burn

```solidity
function burn(address from, uint256 amount) external
```

### cap

```solidity
function cap() external view returns (uint256)
```

### unlockedBalanceOf

```solidity
function unlockedBalanceOf(address account) external view returns (uint256)
```

### pool

```solidity
function pool() external view returns (address)
```

### service

```solidity
function service() external view returns (contract IService)
```

### decimals

```solidity
function decimals() external view returns (uint8)
```

### symbol

```solidity
function symbol() external view returns (string)
```

### tokenType

```solidity
function tokenType() external view returns (enum IToken.TokenType)
```

### lastTGE

```solidity
function lastTGE() external view returns (address)
```

### getTGEList

```solidity
function getTGEList() external view returns (address[])
```

### isPrimaryTGESuccessful

```solidity
function isPrimaryTGESuccessful() external view returns (bool)
```

### addTGE

```solidity
function addTGE(address tge) external
```

### getTotalTGEVestedTokens

```solidity
function getTotalTGEVestedTokens() external view returns (uint256)
```

## IGovernanceSettings

### NewGovernanceSettings

```solidity
struct NewGovernanceSettings {
  uint256 proposalThreshold;
  uint256 quorumThreshold;
  uint256 decisionThreshold;
  uint256 votingDuration;
  uint256 transferValueForDelay;
  uint256[4] executionDelays;
}
```

### setGovernanceSettings

```solidity
function setGovernanceSettings(struct IGovernanceSettings.NewGovernanceSettings settings) external
```

## IGovernorProposals

### service

```solidity
function service() external view returns (contract IService)
```

## ICompaniesRegistry

### CompanyInfo

```solidity
struct CompanyInfo {
  uint256 jurisdiction;
  uint256 entityType;
  string ein;
  string dateOfIncorporation;
  uint256 fee;
}
```

### lockCompany

```solidity
function lockCompany(uint256 jurisdiction, uint256 entityType) external returns (struct ICompaniesRegistry.CompanyInfo)
```

## IRecordsRegistry

### ContractType

```solidity
enum ContractType {
  None,
  Pool,
  GovernanceToken,
  PreferenceToken,
  TGE
}
```

### EventType

```solidity
enum EventType {
  None,
  Transfer,
  TGE,
  GovernanceSettings
}
```

### ContractInfo

```solidity
struct ContractInfo {
  address addr;
  enum IRecordsRegistry.ContractType contractType;
  string description;
}
```

### ProposalInfo

```solidity
struct ProposalInfo {
  address pool;
  uint256 proposalId;
  string description;
}
```

### Event

```solidity
struct Event {
  enum IRecordsRegistry.EventType eventType;
  address pool;
  address eventContract;
  uint256 proposalId;
  string metaHash;
}
```

### addContractRecord

```solidity
function addContractRecord(address addr, enum IRecordsRegistry.ContractType contractType, string description) external returns (uint256 index)
```

### addProposalRecord

```solidity
function addProposalRecord(address pool, uint256 proposalId) external returns (uint256 index)
```

### addEventRecord

```solidity
function addEventRecord(address pool, enum IRecordsRegistry.EventType eventType, address eventContract, uint256 proposalId, string metaHash) external returns (uint256 index)
```

### typeOf

```solidity
function typeOf(address addr) external view returns (enum IRecordsRegistry.ContractType)
```

## IRegistry

## ITokensRegistry

### isTokenWhitelisted

```solidity
function isTokenWhitelisted(address token) external view returns (bool)
```

## ExceptionsLibrary

### ADDRESS_ZERO

```solidity
string ADDRESS_ZERO
```

### INCORRECT_ETH_PASSED

```solidity
string INCORRECT_ETH_PASSED
```

### NO_COMPANY

```solidity
string NO_COMPANY
```

### INVALID_TOKEN

```solidity
string INVALID_TOKEN
```

### NOT_POOL

```solidity
string NOT_POOL
```

### NOT_TGE

```solidity
string NOT_TGE
```

### NOT_Registry

```solidity
string NOT_Registry
```

### NOT_POOL_OWNER

```solidity
string NOT_POOL_OWNER
```

### NOT_SERVICE_OWNER

```solidity
string NOT_SERVICE_OWNER
```

### IS_DAO

```solidity
string IS_DAO
```

### NOT_DAO

```solidity
string NOT_DAO
```

### NOT_WHITELISTED

```solidity
string NOT_WHITELISTED
```

### ALREADY_WHITELISTED

```solidity
string ALREADY_WHITELISTED
```

### ALREADY_NOT_WHITELISTED

```solidity
string ALREADY_NOT_WHITELISTED
```

### NOT_SERVICE

```solidity
string NOT_SERVICE
```

### WRONG_STATE

```solidity
string WRONG_STATE
```

### TRANSFER_FAILED

```solidity
string TRANSFER_FAILED
```

### CLAIM_NOT_AVAILABLE

```solidity
string CLAIM_NOT_AVAILABLE
```

### NO_LOCKED_BALANCE

```solidity
string NO_LOCKED_BALANCE
```

### LOCKUP_TVL_REACHED

```solidity
string LOCKUP_TVL_REACHED
```

### HARDCAP_OVERFLOW

```solidity
string HARDCAP_OVERFLOW
```

### MAX_PURCHASE_OVERFLOW

```solidity
string MAX_PURCHASE_OVERFLOW
```

### HARDCAP_OVERFLOW_REMAINING_SUPPLY

```solidity
string HARDCAP_OVERFLOW_REMAINING_SUPPLY
```

### HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY

```solidity
string HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY
```

### MIN_PURCHASE_UNDERFLOW

```solidity
string MIN_PURCHASE_UNDERFLOW
```

### LOW_UNLOCKED_BALANCE

```solidity
string LOW_UNLOCKED_BALANCE
```

### ZERO_PURCHASE_AMOUNT

```solidity
string ZERO_PURCHASE_AMOUNT
```

### NOTHING_TO_REDEEM

```solidity
string NOTHING_TO_REDEEM
```

### RECORD_IN_USE

```solidity
string RECORD_IN_USE
```

### INVALID_EIN

```solidity
string INVALID_EIN
```

### VALUE_ZERO

```solidity
string VALUE_ZERO
```

### ALREADY_SET

```solidity
string ALREADY_SET
```

### VOTING_FINISHED

```solidity
string VOTING_FINISHED
```

### ALREADY_EXECUTED

```solidity
string ALREADY_EXECUTED
```

### ACTIVE_TGE_EXISTS

```solidity
string ACTIVE_TGE_EXISTS
```

### INVALID_VALUE

```solidity
string INVALID_VALUE
```

### INVALID_CAP

```solidity
string INVALID_CAP
```

### INVALID_HARDCAP

```solidity
string INVALID_HARDCAP
```

### ONLY_POOL

```solidity
string ONLY_POOL
```

### ETH_TRANSFER_FAIL

```solidity
string ETH_TRANSFER_FAIL
```

### TOKEN_TRANSFER_FAIL

```solidity
string TOKEN_TRANSFER_FAIL
```

### BLOCK_DELAY

```solidity
string BLOCK_DELAY
```

### SERVICE_PAUSED

```solidity
string SERVICE_PAUSED
```

### INVALID_PROPOSAL_TYPE

```solidity
string INVALID_PROPOSAL_TYPE
```

### EXECUTION_FAILED

```solidity
string EXECUTION_FAILED
```

### INVALID_USER

```solidity
string INVALID_USER
```

### NOT_LAUNCHED

```solidity
string NOT_LAUNCHED
```

### LAUNCHED

```solidity
string LAUNCHED
```

### VESTING_TVL_REACHED

```solidity
string VESTING_TVL_REACHED
```

### PREFERENCE_TOKEN_EXISTS

```solidity
string PREFERENCE_TOKEN_EXISTS
```

### INVALID_SOFTCAP

```solidity
string INVALID_SOFTCAP
```

### THRESHOLD_NOT_REACHED

```solidity
string THRESHOLD_NOT_REACHED
```

### UNSUPPORTED_TOKEN_TYPE

```solidity
string UNSUPPORTED_TOKEN_TYPE
```

## CompaniesRegistry

### COMPANIES_MANAGER_ROLE

```solidity
bytes32 COMPANIES_MANAGER_ROLE
```

_The constant determines by which role ID contains a list of wallets that have been assigned as managers who have the ability to create new company records in the Registry company repository._

### queue

```solidity
mapping(uint256 => mapping(uint256 => uint256[])) queue
```

_The embedded mappings form a construction, when accessed using two keys at once [jurisdiction][EntityType], you can get lists of ordinal numbers of company records added by managers. These serial numbers can be used when contacting mapping companies to obtain public legal information about the company awaiting purchase by the client._

### companies

```solidity
mapping(uint256 => struct ICompaniesRegistry.CompanyInfo) companies
```

_In this mapping, public legal information is stored about companies that are ready to be acquired by the client and start working as a DAO. The appeal takes place according to the serial number - the key. A list of keys for each type of company and each jurisdiction can be obtained in the queue mapping._

### lastCompanyIndex

```solidity
uint256 lastCompanyIndex
```

_The last sequential number of the last record created by managers in the queue with company data is stored here._

### companyIndex

```solidity
mapping(bytes32 => uint256) companyIndex
```

_Status of combination of (jurisdiction, entityType, EIN) existing_

### CompanyCreated

```solidity
event CompanyCreated(uint256 index, address poolAddress)
```

_Event emitted on company creation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Company list index |
| poolAddress | address | Future pool address |

### CompanyDeleted

```solidity
event CompanyDeleted(uint256 metadataIndex)
```

_Event emitted on company creation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| metadataIndex | uint256 | Company metadata index |

### CompanyFeeUpdated

```solidity
event CompanyFeeUpdated(uint256 jurisdiction, uint256 entityType, uint256 id, uint256 fee)
```

_The event is issued when the manager changes the price of an already created company ready for purchase by the client._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |
| entityType | uint256 | Entity type |
| id | uint256 | Queue index |
| fee | uint256 | Fee for createPool |

### createCompany

```solidity
function createCompany(struct ICompaniesRegistry.CompanyInfo info) public
```

_Create company record - A method for creating a new company record, including its legal data and the sale price._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| info | struct ICompaniesRegistry.CompanyInfo | Company Info |

### lockCompany

```solidity
function lockCompany(uint256 jurisdiction, uint256 entityType) external returns (struct ICompaniesRegistry.CompanyInfo info)
```

_Lock company record - Booking the company for the buyer. During the acquisition of a company, this method searches for a free company at the request of the client (jurisdiction and type of organization), if such exist in the company’s storage reserve, then the method selects the last of the added companies, extracts its record data and sends it as a response for further work of the Service contract, removes its record from the Registry._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| info | struct ICompaniesRegistry.CompanyInfo | Company info |

### deleteCompany

```solidity
function deleteCompany(uint256 jurisdiction, uint256 entityType, uint256 id) external
```

_Delete queue record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |
| entityType | uint256 | Entity type |
| id | uint256 | Queue index |

### updateCompanyFee

```solidity
function updateCompanyFee(uint256 jurisdiction, uint256 entityType, uint256 id, uint256 fee) external
```

_The method that the manager uses to change the value of the company already added earlier in the Registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |
| entityType | uint256 | Entity type |
| id | uint256 | Queue index |
| fee | uint256 | Fee to update |

### companyAvailable

```solidity
function companyAvailable(uint256 jurisdiction, uint256 entityType) external view returns (bool)
```

_This view method is designed to find out whether there is at least one company available for purchase for the jurisdiction and type of organization selected by the user._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |
| entityType | uint256 | Entity type |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Flag if company is available |

### getCompanyPoolAddress

```solidity
function getCompanyPoolAddress(uint256 jurisdiction, uint256 entityType, uint256 id) public view returns (address)
```

_Get company pool address by metadata_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |
| entityType | uint256 | Entity type |
| id | uint256 | Queue id |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | Future company's pool address |

### getCompany

```solidity
function getCompany(uint256 jurisdiction, uint256 entityType, string ein) external view returns (struct ICompaniesRegistry.CompanyInfo)
```

_Get company array by metadata_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Jurisdiction |
| entityType | uint256 | Entity type |
| ein | string | EIN |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct ICompaniesRegistry.CompanyInfo | Company data |

## RecordsRegistry

### contractRecords

```solidity
struct IRecordsRegistry.ContractInfo[] contractRecords
```

_In this array, records are stored about all contracts created by users (that is, about those generated by the service), namely, its index, with which you can extract all available information from other getters._

### ContractIndex

```solidity
struct ContractIndex {
  bool exists;
  uint160 index;
}
```

### indexOfContract

```solidity
mapping(address => struct RecordsRegistry.ContractIndex) indexOfContract
```

_Mapping of contract addresses to their record indexes_

### proposalRecords

```solidity
struct IRecordsRegistry.ProposalInfo[] proposalRecords
```

_List of proposal records_

### events

```solidity
struct IRecordsRegistry.Event[] events
```

_A list of existing events. An event can be either a contract or a specific action performed by a pool based on the results of voting for a promotion (for example, the transfer of funds from a pool contract is considered an event, but does not have a contract, and TGE has both the status of an event and its own separate contract)._

### ContractRecordAdded

```solidity
event ContractRecordAdded(uint256 index, address addr, enum IRecordsRegistry.ContractType contractType)
```

_Event emitted on creation of contract record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |
| addr | address | Contract address |
| contractType | enum IRecordsRegistry.ContractType | Contract type |

### ProposalRecordAdded

```solidity
event ProposalRecordAdded(uint256 index, address pool, uint256 proposalId)
```

_Event emitted on creation of proposal record_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |
| pool | address | Pool address |
| proposalId | uint256 | Proposal ID |

### EventRecordAdded

```solidity
event EventRecordAdded(uint256 index, enum IRecordsRegistry.EventType eventType, address pool, uint256 proposalId)
```

_Event emitted on creation of event_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |
| eventType | enum IRecordsRegistry.EventType | Event type |
| pool | address | Pool address |
| proposalId | uint256 | Proposal ID |

### addContractRecord

```solidity
function addContractRecord(address addr, enum IRecordsRegistry.ContractType contractType, string description) external returns (uint256 index)
```

_This method is used by the main Service contract in order to save the data of the contracts it deploys. After the Registry contract receives the address and type of the created contract from the Service contract, it sends back as a response the sequence number/index assigned to the new record._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | Contract address |
| contractType | enum IRecordsRegistry.ContractType | Contract type |
| description | string |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |

### addProposalRecord

```solidity
function addProposalRecord(address pool, uint256 proposalId) external returns (uint256 index)
```

_This method accepts data from the Service contract about the created nodes in the pools. If there is an internal index of the proposal in the contract of the pool whose shareholders created the proposal, then as a result of using this method, the proposal is given a global index for the entire ecosystem._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |

### addEventRecord

```solidity
function addEventRecord(address pool, enum IRecordsRegistry.EventType eventType, address eventContract, uint256 proposalId, string metaHash) external returns (uint256 index)
```

_This method is used to register events - specific entities associated with the operational activities of pools and the transfer of various values as a result of the use of ecosystem contracts. Each event also has a metahash string field, which is the identifier of the private description of the event stored on the backend._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| eventType | enum IRecordsRegistry.EventType | Event type |
| eventContract | address | Address of the event contract |
| proposalId | uint256 | Proposal ID |
| metaHash | string | Hash value of event metadata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Record index |

### typeOf

```solidity
function typeOf(address addr) external view returns (enum IRecordsRegistry.ContractType)
```

Returns type of given contract

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | Address of contract |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum IRecordsRegistry.ContractType | Contract type |

### contractRecordsCount

```solidity
function contractRecordsCount() external view returns (uint256)
```

Returns number of contract records

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Contract records count |

### proposalRecordsCount

```solidity
function proposalRecordsCount() external view returns (uint256)
```

Returns number of proposal records

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Proposal records count |

### eventRecordsCount

```solidity
function eventRecordsCount() external view returns (uint256)
```

Returns number of event records

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Event records count |

### getGlobalProposalId

```solidity
function getGlobalProposalId(address pool, uint256 proposalId) public view returns (uint256)
```

_Return global proposal ID_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| proposalId | uint256 | Proposal ID |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Global proposal ID |

## RegistryBase

### service

```solidity
address service
```

_Service address_

### onlyService

```solidity
modifier onlyService()
```

### __RegistryBase_init

```solidity
function __RegistryBase_init() internal
```

### setService

```solidity
function setService(address service_) external
```

## TokensRegistry

### WHITELISTED_TOKEN_ROLE

```solidity
bytes32 WHITELISTED_TOKEN_ROLE
```

_Whitelisted token role_

### whitelistTokens

```solidity
function whitelistTokens(address[] tokens) external
```

### isTokenWhitelisted

```solidity
function isTokenWhitelisted(address token) external view returns (bool)
```

_Check if token is whitelisted_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Is token whitelisted |

## ERC20Mock

### constructor

```solidity
constructor(string name_, string symbol_) public
```

## IUniswapFactory

## IUniswapPositionManager

### createAndInitializePoolIfNecessary

```solidity
function createAndInitializePoolIfNecessary(address token0, address token1, uint24 fee, uint160 sqrtPriceX96) external payable returns (address pool)
```

Creates a new pool if it does not exist, then initializes if not initialized

_This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token0 | address | The contract address of token0 of the pool |
| token1 | address | The contract address of token1 of the pool |
| fee | uint24 | The fee amount of the v3 pool for the specified token pair |
| sqrtPriceX96 | uint160 | The initial square root price of the pool as a Q64.96 value |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary |

### multicall

```solidity
function multicall(bytes[] data) external payable returns (bytes[] results)
```

Call multiple functions in the current contract and return the data from all of them if they all succeed

_The `msg.value` should not be trusted for any method callable from multicall._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| data | bytes[] | The encoded function data for each of the calls to make to this contract |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| results | bytes[] | The results from each of the calls passed in via data |

### MintParams

```solidity
struct MintParams {
  address token0;
  address token1;
  uint24 fee;
  int24 tickLower;
  int24 tickUpper;
  uint256 amount0Desired;
  uint256 amount1Desired;
  uint256 amount0Min;
  uint256 amount1Min;
  address recipient;
  uint256 deadline;
}
```

### mint

```solidity
function mint(struct IUniswapPositionManager.MintParams params) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
```

Creates a new position wrapped in a NFT

_Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
a method does not exist, i.e. the pool is assumed to be initialized._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IUniswapPositionManager.MintParams | The params necessary to mint a position, encoded as `MintParams` in calldata |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token that represents the minted position |
| liquidity | uint128 | The amount of liquidity for this position |
| amount0 | uint256 | The amount of token0 |
| amount1 | uint256 | The amount of token1 |

## IWETH

### deposit

```solidity
function deposit() external payable
```

Deposit ether to get wrapped ether

### withdraw

```solidity
function withdraw(uint256) external
```

Withdraw wrapped ether to get ether

