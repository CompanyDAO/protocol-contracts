# Solidity API

## CustomProposal

This contract is designed for constructing proposals from user input. The methods generate calldata from the input arguments and pass it to the specified pool as a proposal.

_It is a supporting part of the protocol that takes user input arguments and constructs OZ Governor-compatible structures describing the transactions to be executed upon successful voting on the proposal. It does not store user input, but only passes it on in a transformed format to the specified pool contract._

### service

```solidity
contract IService service
```

_The address of the Service contract._

### onlyService

```solidity
modifier onlyService()
```

Modifier that makes the function callable only by the Service contract.

_Allows the function to be executed only if the address sending the transaction is equal to the address of the Service contract stored in the memory of this contract._

### onlyForPool

```solidity
modifier onlyForPool(address pool)
```

Modifier that checks the existence of a pool at the given address.

_Checks the existence of the pool for which the proposal is being constructed. The pool should store the same Service contract address as stored in the Custom Proposal contract and be registered in the Registry contract with the corresponding type._

### constructor

```solidity
constructor() public
```

Contract constructor.

_This contract uses OpenZeppelin upgrades and has no need for a constructor function.
The constructor is replaced with an initializer function.
This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused._

### initialize

```solidity
function initialize() public
```

Contract initializer

_This method replaces the constructor for upgradeable contracts._

### setService

```solidity
function setService(address service_) external
```

_Stores a new address of the Service contract in the memory of this contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| service_ | address | The new address of the Service contract. |

### proposeTransfer

```solidity
function proposeTransfer(address pool, address asset, address[] recipients, uint256[] amounts, string description, string metaHash) external returns (uint256 proposalId)
```

This proposal is the only way to withdraw funds from the pool account.

_This function prepares a proposal from the list of recipients and corresponding amounts and submits it to the pool for a vote to transfer those amounts to the specified recipients. The asset type is specified as a separate argument, which is the same for all recipients._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the pool on behalf of which this proposal will be launched and from whose balance the values will be transferred. |
| asset | address | Asset to transfer (address(0) for ETH transfers). |
| recipients | address[] | Transfer recipients. |
| amounts | uint256[] | Transfer amounts. |
| description | string | Proposal description. |
| metaHash | string | Hash value of proposal metadata. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the created proposal. |

### proposeTGE

```solidity
function proposeTGE(address pool, address token, struct ITGE.TGEInfo tgeInfo, struct IToken.TokenInfo tokenInfo, string metadataURI, string description, string metaHash) external returns (uint256 proposalId)
```

This proposal is launched when there is a need to issue additional tokens (both Governance and Preference) for an existing pool. In other words, the issuance of tokens for any DAO is possible only through the creation of such a proposal.

_Proposal to launch a new token generation event (TGE). It can only be created if the maximum supply threshold value for an existing token has not been reached or if a new token is being created, in which case a new token contract will be deployed simultaneously with the TGE contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the pool on behalf of which this proposal will be launched and for which the TGE event will be launched. |
| token | address |  |
| tgeInfo | struct ITGE.TGEInfo | TGE parameters. |
| tokenInfo | struct IToken.TokenInfo | Token parameters. |
| metadataURI | string | TGE metadata URI. |
| description | string | Proposal description. |
| metaHash | string | Hash value of proposal metadata. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the created proposal. |

### proposeGovernanceSettings

```solidity
function proposeGovernanceSettings(address pool, struct IGovernanceSettings.NewGovernanceSettings settings, string description, string metaHash) external returns (uint256 proposalId)
```

Proposal to replace Governance settings. One of the two methods to change voting parameters.

_The main parameter should be a structure of type NewGovernanceSettings, which includes the Governance Threshold, Decision Threshold, Proposal Threshold, and execution delay lists for proposals._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the pool on behalf of which this proposal will be launched and for which the Governance settings will be changed. |
| settings | struct IGovernanceSettings.NewGovernanceSettings | New governance settings. |
| description | string | Proposal description. |
| metaHash | string | Hash value of proposal metadata. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the created proposal. |

### proposeCustomTx

```solidity
function proposeCustomTx(address pool, address[] targets, uint256[] values, bytes[] callDatas, string description, string metaHash) external returns (uint256 proposalId)
```

Creating a custom proposal.

_This tool can be useful for creating a transaction with arbitrary parameters and putting it to a vote for execution on behalf of the pool._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the pool on behalf of which this proposal will be launched. |
| targets | address[] | Transfer recipients. |
| values | uint256[] | Transfer amounts for payable. |
| callDatas | bytes[] | Raw calldatas. |
| description | string | Proposal description. |
| metaHash | string | Hash value of proposal metadata. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the created proposal. |

### proposeTGEERC1155

```solidity
function proposeTGEERC1155(address pool, address token, uint256 tokenId, string tokenIdMetadataURI, struct ITGE.TGEInfo tgeInfo, struct IToken.TokenInfo tokenInfo, string metadataURI, string description, string metaHash) external returns (uint256 proposalId)
```

This proposal is launched when there is a need to issue ERC1155 Preference tokens, additional collections, and token units in existing collections for an existing ERC1155 token. In other words, the issuance of tokens of this format for any DAO is possible only through the creation of such a proposal.

_Proposal to launch a new token generation event (TGE) for ERC1155 preference tokens._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address |  |
| token | address |  |
| tokenId | uint256 | Token ID. |
| tokenIdMetadataURI | string | Token ID metadata URI. |
| tgeInfo | struct ITGE.TGEInfo | TGE parameters. |
| tokenInfo | struct IToken.TokenInfo | Token parameters. |
| metadataURI | string | TGE metadata URI. |
| description | string | Proposal description. |
| metaHash | string | Hash value of proposal metadata. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the created proposal. |

### proposeGovernanceSettingsWithRoles

```solidity
function proposeGovernanceSettingsWithRoles(address pool, struct IGovernanceSettings.NewGovernanceSettings settings, address[] secretary, address[] executor, string description, string metaHash) external returns (uint256 proposalId)
```

Proposal to replace Governance settings and change the pool's list of secretaries and executors. One of the two methods to change voting parameters. The only way for a DAO to modify the lists of secretaries and executors.

_The main parameter should be a structure of type NewGovernanceSettings, which includes the Governance Threshold, Decision Threshold, Proposal Threshold, execution delay lists for proposals, as well as two sets of addresses: one for the new list of secretaries and another for the new list of executors._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the pool on behalf of which this proposal will be launched and for which the Governance settings will be changed. |
| settings | struct IGovernanceSettings.NewGovernanceSettings | New governance settings. |
| secretary | address[] | Add a new address to the pool's secretary list. |
| executor | address[] | Add a new address to the pool's executor list. |
| description | string | Proposal description. |
| metaHash | string | Hash value of the proposal metadata. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the created proposal. |

## Invoice

This contract is designed for managing invoices issued by pools for payment.

_It supports both trusted (payment confirmation off-chain by an authorized address) and trustless (on-chain payment) modes of operation.
Regardless of the presence of Governance tokens in delegation or balance, and regardless of the owner/creator pool status, any address can act as an invoice payer. The following conditions must be met:

- The structure Invoice.sol:invoices for the selected invoice number stores either an empty InvoiceInfo.core.whitelist[] (public invoice), or it contains the payer's address
- The structure Invoice.sol:invoices for the selected invoice number has the values false in the fields InvoiceInfo.isPaid and InvoiceInfo.isCanceled (the invoice has not been canceled or paid by anyone yet)
- The current network block is less than the InvoiceInfo.core.expirationBlock stored in the structure Invoice.sol:invoices for the selected invoice number

When paying the invoice, the amount specified by the invoice creator is debited in the units they have chosen (ERC20 tokens or ETH).

_Note. All the above is valid for on-chain invoice payments. For off-chain invoice payments, a 3rd party backend solution is used to verify the payment of the specified invoice and has its mechanisms for allowing or disallowing the user to pay, including KYC. There is no such blockchain payer in this approach; the invoice is marked as paid by the address assigned the role of SERVICE_MANAGER in the Service contract.__

### registry

```solidity
contract IRegistry registry
```

Адрес контракта Registry

### lastInvoiceIdForPool

```solidity
mapping(address => uint256) lastInvoiceIdForPool
```

Последние созданные пулами инвойсы

_Маппинг, содержащий последний (максимальный) номер инвойса для каждого пула_

### invoices

```solidity
mapping(address => mapping(uint256 => struct IInvoice.InvoiceInfo)) invoices
```

Invoice data (including their state)

_Mapping that stores nested mappings of invoice structures for each pool (pool address is used as the key)_

### eventIndex

```solidity
mapping(address => mapping(uint256 => uint256)) eventIndex
```

Global enumeration of invoices

_For each pool and for each invoice issued by the pool, the mapping contains global event IDs under which the invoices were registered in the Registry contract._

### InvoiceCreated

```solidity
event InvoiceCreated(address pool, uint256 invoiceId)
```

_Event emitted on invoice creating_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| invoiceId | uint256 | InvoiceId for Pool |

### InvoiceCanceled

```solidity
event InvoiceCanceled(address pool, uint256 invoiceId)
```

_Event emitted when invoice is canceled_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| invoiceId | uint256 | InvoiceId for Pool |

### InvoicePaid

```solidity
event InvoicePaid(address pool, uint256 invoiceId)
```

_Event emitted when invoice is paid_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| invoiceId | uint256 | InvoiceId for Pool |

### onlyValidInvoiceManager

```solidity
modifier onlyValidInvoiceManager(address pool)
```

Modifier that allows creating and canceling invoices for a given pool.

_The logic of the modifier is described in the isValidInvoiceManager method. The modifier forwards the arguments to this method and uses its boolean output._

### onlyManager

```solidity
modifier onlyManager()
```

_Modifier to allow only the service manager to call a function._

### whenPoolNotPaused

```solidity
modifier whenPoolNotPaused(address pool)
```

_Modifier to check if the pool is not paused._

### onlyActive

```solidity
modifier onlyActive(address pool, uint256 invoiceId)
```

Modifier that allows manipulation with an existing invoice only if it has the "Active" status.

### constructor

```solidity
constructor() public
```

Contract constructor.

_This contract uses OpenZeppelin upgrades and has no need for a constructor function.
The constructor is replaced with an initializer function.
This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused._

### initialize

```solidity
function initialize(contract IRegistry registry_) external
```

Contract initializer

_This method replaces the constructor for upgradeable contracts. It also sets the registry contract address in the contract's storage._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| registry_ | contract IRegistry | Protocol registry address |

### payInvoice

```solidity
function payInvoice(address pool, uint256 invoiceId) external payable
```

On-chain payment of an invoice (trustless scenario)

_In addition to the specified modifiers, there is also a check for the payer's wallet to be included in the whitelist of invoice payers.
To allow the invoice to be paid by any wallet, the whitelist field should be left empty when creating the invoice.
After successful payment, the invoice receives an irreversible "Paid" status._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the pool contract that issued the invoice |
| invoiceId | uint256 | Identifier of the invoice being paid |

### createInvoice

```solidity
function createInvoice(address pool, struct IInvoice.InvoiceCore core) external
```

Create an invoice by a specified pool

_The onlyValidInvoiceManager modifier determines which accounts can create an invoice for the specified pool.
After creation, the invoice receives an "Active" status._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the pool contract that issues the invoice |
| core | struct IInvoice.InvoiceCore | Invoice payment data (described in the interface) |

### cancelInvoice

```solidity
function cancelInvoice(address pool, uint256 invoiceId) external
```

Cancel an invoice

_To cancel an invoice, the request must pass the onlyValidInvoiceManager modifier, which regulates who can manipulate the pool's invoices on behalf of the pool.
After cancellation, the invoice receives an irreversible "Canceled" status._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the pool contract that issued the invoice |
| invoiceId | uint256 | Invoice identifier |

### setInvoicePaid

```solidity
function setInvoicePaid(address pool, uint256 invoiceId) external
```

Off-chain payment of an invoice (trusted scenario)

_Addresses that have the "SERVICE_MANAGER" role in the Service contract can change the status of any active invoice of any pool to "Paid", indicating a successful payment of the invoice through an off-chain payment method.
After successful payment, the invoice receives an irreversible "Paid" status._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the pool contract that issued the invoice |
| invoiceId | uint256 | Invoice identifier |

### setInvoiceCanceled

```solidity
function setInvoiceCanceled(address pool, uint256 invoiceId) external
```

Canceling an invoice by the manager

_Addresses that have the "SERVICE_MANAGER" role in the Service contract can cancel any active invoice of any pool.
After cancellation, the invoice receives an irreversible "Canceled" status._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the pool contract that issued the invoice |
| invoiceId | uint256 | Invoice identifier |

### validateInvoiceCore

```solidity
function validateInvoiceCore(struct IInvoice.InvoiceCore core) public view returns (bool)
```

This method checks the validity of invoice data during its creation

_An invoice is considered valid if it meets the following criteria:
    - Non-zero payment amount (in any token, including the native network coin)
    - The expiration block has not yet been reached
    - The specified token for payment is a valid ERC20 contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| core | struct IInvoice.InvoiceCore | Invoice data represented by the structure described in the InvoiceCore interface |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the parameters are valid (reverts otherwise) |

### invoiceState

```solidity
function invoiceState(address pool, uint256 invoiceId) public view returns (enum IInvoice.InvoiceState)
```

_This method returns the state of an invoice_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the pool contract that issued the invoice |
| invoiceId | uint256 | The identifier of the invoice |

### isValidInvoiceManager

```solidity
function isValidInvoiceManager(address pool, address account) public view returns (bool)
```

This method checks the account's authority to manipulate pool invoices

_In order to create and cancel pool invoices, the account address must:
    - be listed in the pool's secretaries OR
    - have the "SERVICE_MANAGER" role in the Service contract OR
    - be the owner of the pool if the pool has not yet obtained DAO status_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the pool contract |
| account | address | The account address |

### _setInvoicePaid

```solidity
function _setInvoicePaid(address pool, uint256 invoiceId) private
```

_Implementation of the function that changes the status of an active invoice to "Paid"_

### _setInvoiceCanceled

```solidity
function _setInvoiceCanceled(address pool, uint256 invoiceId) private
```

_Implementation of the function that cancels an active invoice and sets its status to "Canceled"_

## Pool

These contracts are instances of on-chain implementations of user companies. The shareholders of the companies work with them, their addresses are used in the Registry contract as tags that allow obtaining additional legal information (before the purchase of the company by the client). They store legal data (after the purchase of the company by the client). Among other things, the contract is also the owner of the Token and TGE contracts.

_There can be an unlimited number of such contracts, including for one company owner. The contract can be in three states:
1) the company was created by the administrator, a record of it is stored in the Registry, but the contract has not yet been deployed and does not have an owner (buyer) 
2) the contract is deployed, the company has an owner, but there is not yet a successful (softcap primary TGE), in this state its owner has the exclusive right to recreate the TGE in case of their failure (only one TGE can be launched at the same time) 
3) the primary TGE ended successfully, softcap is assembled - the company has received the status of DAO.    The owner no longer has any exclusive rights, all the actions of the company are carried out through the creation and execution of propousals after voting. In this status, the contract is also a treasury - it stores the company's values in the form of ETH and/or ERC20 tokens.
The "Pool owner" status is temporary and is assigned to the address that has successfully purchased a company and in which there has not been a single successful TGE Governance Token. The current owner's address of the company can be obtained by referring to the owner method of the Pool contract. If the isDAO method of the same contract returns "true", then this status does not grant any privileges or exclusive rights and has more of a historical and reference nature.
    As long as the pool is not considered a DAO, the address which is having this status can interact with such methods:
    - TGEFactory.sol:createPrimaryTGE(address poolAddress, IToken.TokenInfo memory tokenInfo, ITGE.TGEInfo memory tgeInfo, string memory metadataURI, IGovernanceSettings.NewGovernanceSettings memory governanceSettings_, address[] memory addSecretary, address[] memory addExecutor) - this method allows you to create a Governance Token compatible with ERC20, with a full set of standard settings, launch a primary TGE for it by deploying the corresponding contract, and also fully configure Governance using the NewGovernanceSettings structure and arrays of addSecretary and addExecutor addresses. The rules set for Governance will become relevant immediately after the successful completion of this primary TGE.
    - Pool.sol:transferByOwner(address to, uint256 amount, address unitOfAccount) - this method allows you to withdraw ETH or any ERC20 token from the pool contract to any address specified by the owner
    Moreover, while in this status, the pool owner, who has not yet become a DAO, can create invoices without restrictions using the Invoice:createInvoice(address pool, InvoiceCore memory core) method.
    In case of a primary TGE failure, the company owner continues to use their unique status, which means they can recreate the token, TGE, and set new Governance settings within a single transaction._

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

_Mapping for Governance Token. There can be only one valid Governance token._

### lastProposalIdForAddress

```solidity
mapping(address => uint256) lastProposalIdForAddress
```

_last proposal id for address. This method returns the proposal Id for the last proposal created by the specified address._

### proposalCreatedAt

```solidity
mapping(uint256 => uint256) proposalCreatedAt
```

_Mapping that stores the blocks of proposal creation for this pool. The main information about the proposal is stored in variables provided by the Governor.sol contract, which is inherited by this contract._

### tokensFullList

```solidity
mapping(enum IToken.TokenType => address[]) tokensFullList
```

_A list of tokens belonging to this pool. There can be only one valid Governance token and several Preference tokens with different settings. The mapping key is the token type (token type encoding is specified in the IToken.sol interface). The value is an array of token identifiers._

### tokenTypeByAddress

```solidity
mapping(address => enum IToken.TokenType) tokenTypeByAddress
```

_Mapping that stores information about the type of each token. The mapping key is the address of the token contract, and the value is the digital code of the token type._

### poolSecretary

```solidity
struct EnumerableSetUpgradeable.AddressSet poolSecretary
```

This collection of addresses is part of the simplified role model of the pool and stores the addresses of accounts that have been assigned the role of pool secretary.

_Pool secretary is an internal pool role with responsibilities that include working with invoices and creating proposals. This role serves to give authority, similar to a shareholder, to an account that does not have Governance Tokens (e.g., a hired employee)._

### lastExecutedProposalId

```solidity
uint256 lastExecutedProposalId
```

_Identifier of the last executed proposal_

### proposalIdToTGE

```solidity
mapping(uint256 => address) proposalIdToTGE
```

_Mapping that stores the addresses of TGE contracts that have been deployed as part of proposal execution, using the identifiers of those proposals as keys._

### poolExecutor

```solidity
struct EnumerableSetUpgradeable.AddressSet poolExecutor
```

This collection of addresses is part of the simplified role model of the pool and stores the addresses of accounts that have been assigned the role of pool executor.

_Pool Executor is an internal pool role with responsibilities that include executing proposals that have ended with a "for" decision in voting and have completed their time in the delayed state._

### OAurl

```solidity
string OAurl
```

_Operating Agreement Url_

### onlyService

```solidity
modifier onlyService()
```

Modifier that allows the method to be called only by the Service contract.

_It is used to transfer control of the Registry and deployable user contracts for the final configuration of the company._

### onlyTGEFactory

```solidity
modifier onlyTGEFactory()
```

Modifier that allows the method to be called only by the TGEFactory contract.

_Used during TGE creation, where the TGEFactory contract deploys contracts and informs their addresses to the pool contract for storage._

### onlyServiceAdmin

```solidity
modifier onlyServiceAdmin()
```

Modifier that allows the method to be called only by an account that has the ADMIN role in the Service contract.

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(struct ICompaniesRegistry.CompanyInfo companyInfo_) external
```

_Initialization of a new pool and placement of user settings and data (including legal ones) in it_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| companyInfo_ | struct ICompaniesRegistry.CompanyInfo | Legal company data |

### setNewOwnerWithSettings

```solidity
function setNewOwnerWithSettings(address newowner, string trademark_, struct IGovernanceSettings.NewGovernanceSettings governanceSettings_) external
```

Actions after purchasing a pool (including ownership transfer and governance settings)

_This is executed only during a successful execution of purchasePool in the Service contract. The address that is mentioned in the 'newowner' field of the transaction calldata becomes the pool owner.
An internal pool role, relevant from the moment of purchasing a company until the first successful TGE. The sole and unchangeable wallet possessing this role is the account that paid the fee for creating the company. Once the pool becomes a DAO, this role no longer has any exclusive powers.
    The appointment of the Owner's address is done within the call to Pool.sol:setNewOwnerWithSettings(address newowner, string memory trademark_, NewGovernanceSettings memory governanceSettings_), which occurs when a new owner purchases the company._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newowner | address | Address of the new contract owner account |
| trademark_ | string | Company trademark |
| governanceSettings_ | struct IGovernanceSettings.NewGovernanceSettings | Governance settings (voting rules, etc.) |

### setSettings

```solidity
function setSettings(struct IGovernanceSettings.NewGovernanceSettings governanceSettings_, address[] secretary, address[] executor) external
```

Changing the governance settings of the pool as a result of voting or the owner's initial pool setup

_This method can be called in one of two cases:
- The pool has attained DAO status, and a proposal including a transaction calling this method has been executed
- The pool has not yet attained DAO status, and the pool owner initiates the initial TGE with new governance settings as arguments_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| governanceSettings_ | struct IGovernanceSettings.NewGovernanceSettings | Governance settings |
| secretary | address[] | List of secretary addresses |
| executor | address[] | List of executor addresses |

### setCompanyInfo

```solidity
function setCompanyInfo(uint256 _jurisdiction, uint256 _entityType, string _ein, string _dateOfIncorporation, string _OAuri) external
```

Setting legal data for the corresponding company pool

_This method is executed as part of the internal transaction in the setCompanyInfoForPool method of the Registry contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _jurisdiction | uint256 | Digital code of the jurisdiction |
| _entityType | uint256 | Digital code of the organization type |
| _ein | string | Government registration number of the company |
| _dateOfIncorporation | string | Date of incorporation of the company |
| _OAuri | string | Operating Agreement URL |

### receive

```solidity
receive() external payable
```

_Method for receiving an Ethereum contract that issues an event._

### castVote

```solidity
function castVote(uint256 proposalId, bool support) external
```

Method for voting "for" or "against" a given proposal

_This method calls the _castVote function defined in the Governor.sol contract.
Since proposals in the CompanyDAO protocol can be prematurely finalized, after each successful invocation of this method, a check is performed for the occurrence of such conditions._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Pool proposal ID |
| support | bool | "True" for voting "for", "False" for voting "against" |

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

### setProposalIdToTGE

```solidity
function setProposalIdToTGE(address tge) external
```

_This method adds a record to the proposalIdToTGE mapping indicating that a TGE contract with the specified address was deployed as a result of executing the proposal with the lastExecutedProposalId identifier._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE address |

### executeProposal

```solidity
function executeProposal(uint256 proposalId) external
```

This method is used to initiate the execution of a proposal.

_For this method to work, the following conditions must be met:
    - The transaction sender must be a valid executor (more details in the isValidExecutor function)
    - The proposal must have the "Awaiting Execution" status._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### cancelProposal

```solidity
function cancelProposal(uint256 proposalId) external
```

Method for emergency cancellation of a proposal.

_Cancel a proposal, callable only by the Service contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### propose

```solidity
function propose(address proposer, uint256 proposeType, struct IGovernor.ProposalCoreData core, struct IGovernor.ProposalMetaData meta) external returns (uint256 proposalId)
```

_Creating a proposal and assigning it a unique identifier to store in the list of proposals in the Governor contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposer | address |  |
| proposeType | uint256 |  |
| core | struct IGovernor.ProposalCoreData | Proposal core data |
| meta | struct IGovernor.ProposalMetaData | Proposal meta data |

### transferByOwner

```solidity
function transferByOwner(address to, uint256 amount, address unitOfAccount) external
```

Transfers funds from the pool's account to a specified address.

_This method can only be called by the pool owner and only during the period before the pool becomes a DAO._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The recipient's address |
| amount | uint256 | The transfer amount |
| unitOfAccount | address | The unit of account (token contract address or address(0) for ETH) |

### customTxByOwner

```solidity
function customTxByOwner(address target, uint256 value, bytes data) external
```

_Execute custom tx if the pool is not yet a  DAO_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| target | address | receiver addresss |
| value | uint256 | transfer amount |
| data | bytes | input data of the transaction |

### isDAO

```solidity
function isDAO() public view returns (bool)
```

_Checks if the pool has achieved DAO status.
A pool achieves DAO status if it has a valid governance token and the primary TGE was successful._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | isDao True if the pool is a DAO, false otherwise. |

### owner

```solidity
function owner() public view returns (address)
```

_Returns the owner of the pool._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the pool owner. |

### getTokens

```solidity
function getTokens(enum IToken.TokenType tokenType) external view returns (address[])
```

_Returns the list of tokens associated with the pool based on the token type._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenType | enum IToken.TokenType | The type of tokens to retrieve. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | The array of token addresses. |

### getGovernanceToken

```solidity
function getGovernanceToken() public view returns (contract IToken)
```

_Returns the governance token associated with the pool._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | contract IToken | The governance token address. |

### tokenExists

```solidity
function tokenExists(contract IToken token) public view returns (bool)
```

_Checks if a token exists in the pool._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | contract IToken | The token to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the token exists, false otherwise. |

### getPoolSecretary

```solidity
function getPoolSecretary() external view returns (address[])
```

_Returns the list of pool secretaries._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | The array of pool secretary addresses. |

### getPoolExecutor

```solidity
function getPoolExecutor() external view returns (address[])
```

_Returns the list of pool executors._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | The array of pool executor addresses. |

### isPoolSecretary

```solidity
function isPoolSecretary(address account) public view returns (bool)
```

_Checks if an address is a pool secretary._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the address is a pool secretary, false otherwise. |

### isPoolExecutor

```solidity
function isPoolExecutor(address account) public view returns (bool)
```

_Checks if an address is a pool executor._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the address is a pool executor, false otherwise. |

### isValidProposer

```solidity
function isValidProposer(address account) public view returns (bool)
```

_Checks if an address is a valid proposer for creating proposals._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the address is a valid proposer, false otherwise. |

### isValidExecutor

```solidity
function isValidExecutor(address account) public view returns (bool)
```

_Checks if an address is a valid executor for executing ballot proposals._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address to check. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the address is a valid executor, false otherwise. |

### isLastProposalIdByTypeActive

```solidity
function isLastProposalIdByTypeActive(uint256 type_) public view returns (bool)
```

_Checks if the last proposal of a specific type is active._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| type_ | uint256 | The type of proposal. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | True if the last proposal of the given type is active, false otherwise. |

### validateGovernanceSettings

```solidity
function validateGovernanceSettings(struct IGovernanceSettings.NewGovernanceSettings settings) external pure
```

_Validates the governance settings for creating proposals._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| settings | struct IGovernanceSettings.NewGovernanceSettings | The governance settings to validate. |

### availableVotesForProposal

```solidity
function availableVotesForProposal(uint256 proposalId) external view returns (uint256)
```

_Returns the available votes for a proposal at the current block._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the proposal. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The available votes for the proposal. |

### _afterProposalCreated

```solidity
function _afterProposalCreated(uint256 proposalId) internal
```

_Internal function to be called after a proposal is created._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | The ID of the created proposal. |

### _getCurrentVotes

```solidity
function _getCurrentVotes(address account) internal view returns (uint256)
```

_Internal function to get the current votes of an account._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account's address. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The current votes of the account. |

### _getBlockTotalVotes

```solidity
function _getBlockTotalVotes(uint256 blocknumber) internal view returns (uint256)
```

_Internal function to get the total votes in the pool at a specific block._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| blocknumber | uint256 | The block number. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The total votes at the given block. |

### _getPastVotes

```solidity
function _getPastVotes(address account, uint256 blockNumber) internal view returns (uint256)
```

_Internal function to get the past votes of an account at a specific block._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account's address. |
| blockNumber | uint256 | The block number. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The past votes of the account at the given block. |

### _setLastProposalIdForAddress

```solidity
function _setLastProposalIdForAddress(address proposer, uint256 proposalId) internal
```

_Internal function to set the last proposal ID for an address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposer | address | The proposer's address. |
| proposalId | uint256 | The proposal ID. |

## Registry

This contract serves as a registry to store all events, contracts, and proposals of all pools using global sequential numbering.

_The repository of all user and business entities created by the protocol: companies to be implemented, contracts to be deployed, proposals created by shareholders. The main logic of the registry is implemented in contracts that inherit from Registry._

### globalProposalIds

```solidity
mapping(address => mapping(uint256 => uint256)) globalProposalIds
```

_This mapping stores the correspondence between the pool address, the local proposal number, and its global number registered in the registry._

### Log

```solidity
event Log(address sender, address receiver, uint256 value, bytes data)
```

### constructor

```solidity
constructor() public
```

Contract constructor.

_This contract uses OpenZeppelin upgrades and has no need for a constructor function.
The constructor is replaced with an initializer function.
This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused._

### initialize

```solidity
function initialize() public
```

Contract initializer

_This method replaces the constructor for upgradeable contracts._

### setGlobalProposalId

```solidity
function setGlobalProposalId(address pool, uint256 proposalId, uint256 globalProposalId) internal
```

_Update global proposal ID_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| proposalId | uint256 | Local Proposal ID |
| globalProposalId | uint256 | Global Proposal ID |

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

### log

```solidity
function log(address sender, address receiver, uint256 value, bytes data) external
```

## Service

The main contract of the protocol, the starting point of interaction for new clients.

_This contract deploys the core OZ Access Control model, where the distribution of accounts determines the behavior of most modifiers.
The address of this contract is specified in all other contracts, and this contract also stores the addresses of those contracts. The mutual references between contracts implement a system of "own-foreign" recognition.
This contract is responsible for updating itself and all other protocol contracts, including user contracts._

### DENOM

```solidity
uint256 DENOM
```

Denominator for shares (such as thresholds)

_The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account._

### ADMIN_ROLE

```solidity
bytes32 ADMIN_ROLE
```

Hash code of the ADMIN role for the OZ Access Control model

_The main role of the entire ecosystem, the protocol owner. The address assigned to this role can perform all actions related to updating contract implementations or interacting with or configuring the protocol's Treasury. The administrator can cancel suspicious proposals awaiting execution, pause the operation of protocol contracts and pools. In addition, the administrator can perform all actions provided for the SERVICE_MANAGER role.
    The holder of this role can assign the roles of ADMIN, WHITELISTED_USER, and SERVICE_MANAGER to other accounts.
    Storage, assignment, and revocation of the role are carried out using the standard methods of the AccessControl model from OpenZeppelin: grantRole, revokeRole, setRole._

### SERVICE_MANAGER_ROLE

```solidity
bytes32 SERVICE_MANAGER_ROLE
```

Hash code of the MANAGER role for the OZ Access Control model

_The administrator can delegate some of their powers to the owners of addresses assigned the SERVICE_MANAGER role. The administrator can also perform all the methods listed below. This role is assigned and removed by the administrator and was created for assigning addresses managed by worker scripts (automatic backend modules whose task is to constantly track changes in the states of all ecosystem components and initiate transactions that make actual changes and involve necessary scenarios for certain contracts at the moment).
    In addition, the holder of this role has the same powers as the holders of the Secretary and Executor roles in any pool, assigned by its shareholders.
    The holder of this role can assign the WHITELISTED_USER role to other accounts.
    Storage, assignment, and revocation of the role are carried out using the standard methods of the AccessControl model from OpenZeppelin: grantRole, revokeRole, setRole._

### WHITELISTED_USER_ROLE

```solidity
bytes32 WHITELISTED_USER_ROLE
```

Legacy hash code of users added to the whitelist. Currently unused role.

### EXECUTOR_ROLE

```solidity
bytes32 EXECUTOR_ROLE
```

Hash code of the EXECUTOR role for the OZ Access Control model

### registry

```solidity
contract IRegistry registry
```

_Address of the Registry contract_

### poolBeacon

```solidity
address poolBeacon
```

_Address of the Pool beacon contract_

### tokenBeacon

```solidity
address tokenBeacon
```

_Address of the Token beacon contract_

### tgeBeacon

```solidity
address tgeBeacon
```

_Address of the TGE beacon contract_

### protocolTreasury

```solidity
address protocolTreasury
```

Address to hold the commission from TGE in distributed tokens

_0.1% (can be changed by the admin) of all Governance tokens from successful TGE are held here_

### protocolTokenFee

```solidity
uint256 protocolTokenFee
```

The fee size that the protocol charges in tokens from each successful TGE (only for Governance Tokens)

_Protocol token fee percentage value with 4 decimals.
Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000_

### protolCollectedFee

```solidity
mapping(address => uint256) protolCollectedFee
```

Total fees collected from TGE in Governance tokens for each pool

_Protocol token fee claimed for tokens_

### customProposal

```solidity
contract ICustomProposal customProposal
```

_Address of the Proposal beacon contract_

### vesting

```solidity
contract IVesting vesting
```

_Address of the Vesting contract_

### invoice

```solidity
contract IInvoice invoice
```

_Address of the Invoice contract_

### tokenFactory

```solidity
contract ITokenFactory tokenFactory
```

_Address of the TokenFactory contract_

### tgeFactory

```solidity
contract ITGEFactory tgeFactory
```

_Address of the TGEFactory contract_

### tokenERC1155Beacon

```solidity
address tokenERC1155Beacon
```

_Address of the Token beacon contract (for ERC1155 tokens)_

### PoolCreated

```solidity
event PoolCreated(address pool, address token, address tge)
```

_Event emitted upon deployment of a pool contract (i.e., creation of a pool)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the Pool contract |
| token | address | Address of the pool's token contract (usually 0, as the pool and token contracts are deployed separately) |
| tge | address | Address of the TGE contract (usually 0, as the pool and TGE contracts are deployed separately) |

### PoolPurchased

```solidity
event PoolPurchased(address pool, address token, address tge)
```

_Event emitted upon the purchase of a pool_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the purchased pool |
| token | address | Address of the pool's token contract (usually 0, as the pool does not have any tokens at the time of purchase) |
| tge | address | Address of the TGE contract (usually 0) |

### ProtocolTreasuryChanged

```solidity
event ProtocolTreasuryChanged(address protocolTreasury)
```

_Event emitted when the balance of the Protocol Treasury changes due to transfers of pool tokens collected as protocol fees._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protocolTreasury | address | Address of the Protocol Treasury |

### ProtocolTokenFeeChanged

```solidity
event ProtocolTokenFeeChanged(uint256 protocolTokenFee)
```

_Event emitted when the protocol changes the token fee collected from pool tokens._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| protocolTokenFee | uint256 | New protocol token fee |

### FeesTransferred

```solidity
event FeesTransferred(address to, uint256 amount)
```

_Event emitted when the service fees are transferred to another address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Transfer recipient |
| amount | uint256 | Amount of ETH transferred |

### ProposalCancelled

```solidity
event ProposalCancelled(address pool, uint256 proposalId)
```

_Event emitted when a proposal is canceled by an account with the Service Manager role_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Pool address |
| proposalId | uint256 | Pool local proposal id |

### PoolBeaconChanged

```solidity
event PoolBeaconChanged(address beacon)
```

_Event emitted on PoolBeacon change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beacon | address | Beacon address |

### TGEBeaconChanged

```solidity
event TGEBeaconChanged(address beacon)
```

_Event emitted on TGEBeacon change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beacon | address | Beacon address |

### TokenBeaconChanged

```solidity
event TokenBeaconChanged(address beacon)
```

_Event emitted on TokenBeacon change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beacon | address | Beacon address |

### CustomPropsalChanged

```solidity
event CustomPropsalChanged(address proxy)
```

_Event emitted on CustomPropsalProxy change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proxy | address | Proxy address |

### InvoiceChanged

```solidity
event InvoiceChanged(address proxy)
```

_Event emitted on InvoiceProxy change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proxy | address | Proxy address |

### RegistryChanged

```solidity
event RegistryChanged(address proxy)
```

_Event emitted on RegistryProxy change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proxy | address | Proxy address |

### TGEFactoryChanged

```solidity
event TGEFactoryChanged(address proxy)
```

_Event emitted on TGEFactoryProxy change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proxy | address | Proxy address |

### TokenFactoryChanged

```solidity
event TokenFactoryChanged(address proxy)
```

_Event emitted on TokenFactoryProxy change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proxy | address | Proxy address |

### VestingChanged

```solidity
event VestingChanged(address proxy)
```

_Event emitted on VestingProxy change._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proxy | address | Proxy address |

### onlyPool

```solidity
modifier onlyPool()
```

Modifier that allows the method to be called only by the Pool contract.

### onlyTGE

```solidity
modifier onlyTGE()
```

Modifier that allows the method to be called only by the TGE contract.

### onlyRegistry

```solidity
modifier onlyRegistry()
```

Modifier that allows the method to be called only by the Registry contract.

### onlyManager

```solidity
modifier onlyManager()
```

Modifier that allows the method to be called only by an account with the ADMIN role in the Registry contract.

### constructor

```solidity
constructor() public
```

Contract constructor.

_This contract uses OpenZeppelin upgrades and has no need for a constructor function.
The constructor is replaced with an initializer function.
This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused._

### initialize

```solidity
function initialize(contract IRegistry registry_, contract ICustomProposal customProposal_, contract IVesting vesting_, address poolBeacon_, address tokenBeacon_, address tgeBeacon_, uint256 protocolTokenFee_) external
```

_Initializer function, can only be called once_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| registry_ | contract IRegistry | Registry address |
| customProposal_ | contract ICustomProposal | Custom proposals address |
| vesting_ | contract IVesting | Vesting address |
| poolBeacon_ | address | Pool beacon |
| tokenBeacon_ | address | Governance token beacon |
| tgeBeacon_ | address | TGE beacon |
| protocolTokenFee_ | uint256 | Protocol token fee |

### purchasePool

```solidity
function purchasePool(uint256 jurisdiction, uint256 entityType, string trademark, struct IGovernanceSettings.NewGovernanceSettings governanceSettings) external payable
```

Method for purchasing a pool by the user. Among the data submitted for input, there are jurisdiction and Entity Type

_The user refers to the Service protocol's purchasePool method, in which arguments indicate the digital jurisdiction code and the digital organizational type code of the company (as well as Governance settings provided by the NewGovernanceSettings interface, and a string record that will serve as the company's trademark). If there is at least one unoccupied and available company for purchase in the Registry contract (queue record with keys in the form of user-transmitted jurisdiction and organizational type codes), the following actions occur:
    -    reserving the company for the user (removing it from the list of available ones)
    -    debiting the commission in ETH (in fact, the company's price) from the user's balance, which is equal to the fee field in the CompanyInfo structure stored in the companies of the Registry contract
    -    making changes to the contract through an internal transaction using the setNewOwnerWithSettings method, which includes changing the company's trademark, its owner, and Governance settings.
    From this point on, the user is considered the Owner of the company._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Digital code of the jurisdiction. |
| entityType | uint256 | Digital code of the entity type. |
| trademark | string | Company's trademark. |
| governanceSettings | struct IGovernanceSettings.NewGovernanceSettings | Initial Governance settings. |

### transferPurchasedPoolByService

```solidity
function transferPurchasedPoolByService(address newowner, uint256 jurisdiction, uint256 entityType, string trademark, struct IGovernanceSettings.NewGovernanceSettings governanceSettings) external
```

Method for manually transferring the company to a new owner.

_This method can be used when paying for the company's cost (protocol fee) through any other means (off-chain payment)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newowner | address |  |
| jurisdiction | uint256 | Digital code of the jurisdiction. |
| entityType | uint256 | Digital code of the entity type. |
| trademark | string | Company's trademark. |
| governanceSettings | struct IGovernanceSettings.NewGovernanceSettings | Initial Governance settings. |

### addProposal

```solidity
function addProposal(uint256 proposalId) external
```

Adding a new record of a proposal to the Registry.

_To ensure the security and consistency of the contract architecture, user contracts do not directly interact with the Registry.
Due to the complexity of the role model for creating proposals, registering a new record is performed from the central contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID. |

### addEvent

```solidity
function addEvent(enum IRecordsRegistry.EventType eventType, uint256 proposalId, string metaHash) external
```

Adding a new record of an event to the Registry.

_To ensure the security and consistency of the contract architecture, user contracts do not directly interact with the Registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| eventType | enum IRecordsRegistry.EventType | Event type. |
| proposalId | uint256 | Proposal ID. |
| metaHash | string | Hash value of event metadata. |

### addInvoiceEvent

```solidity
function addInvoiceEvent(address pool, uint256 invoiceId) external returns (uint256)
```

### createPool

```solidity
function createPool(struct ICompaniesRegistry.CompanyInfo companyInfo) external
```

Method for deploying a pool contract.

_When working with the Registry contract, the address that has the COMPANIES_MANAGER role in that contract can deploy the pool contract by sending a transaction with the company's legal data as an argument._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| companyInfo | struct ICompaniesRegistry.CompanyInfo | Company info. |

### transferCollectedFees

```solidity
function transferCollectedFees(address to) external
```

_Transfer the collected protocol fees obtained from the sale of pools to the specified address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The transfer recipient. |

### setFactories

```solidity
function setFactories(contract ITokenFactory tokenFactory_, contract ITGEFactory tgeFactory_) external
```

_Sets factories for previously deployed service_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenFactory_ | contract ITokenFactory | TokenFactory address |
| tgeFactory_ | contract ITGEFactory | TGEFactory address |

### setProtocolCollectedFee

```solidity
function setProtocolCollectedFee(address _token, uint256 _protocolTokenFee) public
```

Method to account for the collected protocol fees.

_This method is called after each successful Governance Token Generation Event (TGE) and increases the record of the collected Governance Tokens for this pool._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | address | The address of the token contract. |
| _protocolTokenFee | uint256 | The amount of tokens collected as protocol fees. |

### setProtocolTreasury

```solidity
function setProtocolTreasury(address _protocolTreasury) public
```

_Set a new address for the protocol treasury, where the Governance tokens collected as protocol fees will be transferred._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _protocolTreasury | address | The new address of the protocol treasury. |

### setProtocolTokenFee

```solidity
function setProtocolTokenFee(uint256 _protocolTokenFee) public
```

_Set a new value for the protocol token fee percentage._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _protocolTokenFee | uint256 | The new protocol token fee percentage value with 4 decimals. Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000. |

### setRegistry

```solidity
function setRegistry(contract IRegistry _registry) external
```

_Sets new Registry contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _registry | contract IRegistry | registry address |

### setCustomProposal

```solidity
function setCustomProposal(contract ICustomProposal _customProposal) external
```

_Sets new customProposal contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _customProposal | contract ICustomProposal | customProposal address |

### setVesting

```solidity
function setVesting(contract IVesting _vesting) external
```

_Sets new vesting_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _vesting | contract IVesting | vesting address |

### setInvoice

```solidity
function setInvoice(contract IInvoice _invoice) external
```

_Sets new invoice contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _invoice | contract IInvoice | invoice address |

### setPoolBeacon

```solidity
function setPoolBeacon(address beacon) external
```

_Sets new pool beacon_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beacon | address | Beacon address |

### setTokenBeacon

```solidity
function setTokenBeacon(address beacon) external
```

_Sets new token beacon_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beacon | address | Beacon address |

### setTokenERC1155Beacon

```solidity
function setTokenERC1155Beacon(address beacon) external
```

_Sets new tokenERC1155 beacon_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beacon | address | Beacon address |

### setTGEBeacon

```solidity
function setTGEBeacon(address beacon) external
```

_Sets new TGE beacon_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| beacon | address | Beacon address |

### cancelProposal

```solidity
function cancelProposal(address pool, uint256 proposalId) public
```

Cancel a proposal by the administrator.

_This method is used for emergency cancellation of any proposal by an address with the ADMIN role in this contract. It is used to prevent the execution of transactions prescribed by the proposal if there are doubts about their safety._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the pool contract. |
| proposalId | uint256 | The ID of the proposal. |

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

### paused

```solidity
function paused() public view returns (bool)
```

_Returns true if the contract is paused, and false otherwise._

### getMinSoftCap

```solidity
function getMinSoftCap() public view returns (uint256)
```

This method returns the minimum soft cap accepted in the protocol.

_Due to the fact that each issuance of Governance tokens involves collecting a portion of the tokens as a fee, this calculation is used to avoid conflicts related to rounding._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The minimum soft cap. |

### getProtocolTokenFee

```solidity
function getProtocolTokenFee(uint256 amount) public view returns (uint256)
```

This method returns the size of the protocol fee charged for issuing Governance tokens.

_The calculation is based on DENOM and the current fee rate, allowing the fee to be calculated for any amount of tokens planned for distribution._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The token amount. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The size of the fee in tokens. |

### getProtocolCollectedFee

```solidity
function getProtocolCollectedFee(address token_) external view returns (uint256)
```

This method returns the amount of Governance tokens collected as a protocol fee for each pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token_ | address | The address of the token contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of collected protocol fee. |

### getMaxHardCap

```solidity
function getMaxHardCap(address _pool) public view returns (uint256)
```

This method returns the maximum number of Governance tokens that can be issued in all subsequent TGEs for the pool.

_Due to the protocol fee mechanism, which involves minting new token units as a protocol fee, calculating this maximum can be more complex than it seems at first glance. This method takes into account reserved and potential token units and calculates the hardcap accordingly._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pool | address | The address of the pool contract for which the calculation is required. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The maximum hardcap value. |

### validateTGEInfo

```solidity
function validateTGEInfo(struct ITGE.TGEInfo info, uint256 cap, uint256 totalSupplyWithReserves, enum IToken.TokenType tokenType) external view
```

_This method is used for formal validation of user-defined parameters for the conducted TGE._

### getPoolAddress

```solidity
function getPoolAddress(struct ICompaniesRegistry.CompanyInfo info) public view returns (address)
```

_This method calculates the address of the pool contract using the create2 algorithm._

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

_Intermediate calculation for the create2 algorithm_

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

_Creating and initializing a pool_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | Pool contract address |

## TGE

The Token Generation Event (TGE) is the cornerstone of everything related to tokens issued on the CompanyDAO protocol. TGE contracts contain the rules and deadlines for token distribution events and can influence the pool's operational activities even after they have ended.
    The launch of the TGE event takes place simultaneously with the deployment of the contract, after which the option to purchase tokens becomes immediately available. Tokens purchased by a user can be partially or fully minted to the buyer's address and can also be placed in the vesting reserve either in full or for the remaining portion. Additionally, tokens acquired during the TGE and held in the buyer's balance may have their transfer functionality locked (the user owns, uses them as votes, delegates, but cannot transfer the tokens to another address).

_TGE events differ by the type of tokens being distributed:
    - Governance Token Generation Event
    - Preference Token Generation Event
    When deploying the TGE contract, among other arguments, the callData field contains the token field, which contains the address of the token contract that will interact with the TGE contract. The token type can be determined from the TokenType state variable of the token contract.
    Differences between these types:
    - Governance Token Generation Event involves charging a ProtocolTokenFee in the amount set in the Service:protocolTokenFee value (percentages in DENOM notation). This fee is collected through the transferFunds() transaction after the completion of the Governance token distribution event (the funds collected from buyers go to the pool balance, and the protocolTokenFee is minted and sent to the Service:protocolTreasury).
    - Governance Token Generation Event has a mandatory minPurchase limit equal to the Service:protocolTokenFee (in the smallest indivisible token parts, taking into account Decimals and DENOM). This is done to avoid rounding conflicts or overcharges when calculating the fee for each issued token volume.
    - In addition to being launched as a result of a proposal execution, a Governance Token Generation Event can be launched by the pool Owner as long as the pool has not acquired DAO status. Preference Token Generation Event can only be launched as a result of a proposal execution.
    - A successful Governance Token Generation Event (see TGE states later) leads to the pool becoming a DAO if it didn't previously have that status.
    @dev **TGE events differ by the number of previous launches:**
    - primary TGE
    - secondary TGE
    As long as the sum of the totalSupply and the vesting reserve of the distributed token does not equal the cap, a TGE can be launched to issue some more of these tokens.
    The first TGE for the distribution of any token is called primary, and all subsequent ones are called secondary.
    Differences between these types:
    - A transaction to launch a primary TGE involves the simultaneous deployment of the token contract, while a secondary TGE only works with an existing token contract.
    - A secondary TGE does not have a softcap parameter, meaning that after at least one minPurchase of tokens, the TGE is considered successful.
    - When validating the hardcap (i.e., the maximum possible number of tokens available for sale/distribution within the TGE) during the creation of a primary TGE, only a formal check is performed (hardcap must not be less than softcap and not greater than cap). For a secondary TGE, tokens that will be minted during vesting claims are also taken into account.
    - In case of failure of a primary TGE for any token, that token is not considered to have any application within the protocol. It is no longer possible to conduct a TGE for such a token._

### DENOM

```solidity
uint256 DENOM
```

Denominator for shares (such as thresholds)

_The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account._

### token

```solidity
address token
```

The address of the ERC20/ERC1155 token being distributed in this TGE

_Mandatory setting for TGE, only one token can be distributed in a single TGE event_

### tokenId

```solidity
uint256 tokenId
```

The identifier of the ERC1155 token collection

_For ERC1155, there is an additional restriction that units of only one collection of such tokens can be distributed in a single TGE_

### info

```solidity
struct ITGE.TGEInfo info
```

_Parameters for conducting the TGE, described by the ITGE.sol:TGEInfo interface_

### _isUserWhitelisted

```solidity
mapping(address => bool) _isUserWhitelisted
```

A whitelist of addresses allowed to participate in this TGE

_A TGE can be public or private. To make the event public, simply leave the whitelist empty.
    The TGE contract can act as an airdrop - a free token distribution. To do this, set the price value to zero.
    To create a DAO with a finite number of participants, each of whom should receive an equal share of tokens, you can set the whitelist when launching the TGE as a list of the participants' addresses, and set both minPurchase and maxPurchase equal to the expression (hardcap / number of participants). To make the pool obtain DAO status only if the distribution is successful under such conditions for all project participants, you can set the softcap value equal to the hardcap. With these settings, the company will become a DAO only if all the initial participants have an equal voting power._

### createdAt

```solidity
uint256 createdAt
```

_The block on which the TGE contract was deployed and the event begins_

### purchaseOf

```solidity
mapping(address => uint256) purchaseOf
```

_A mapping that stores the amount of token units purchased by each address that plays a key role in the TGE._

### totalPurchased

```solidity
uint256 totalPurchased
```

_Total amount of tokens purchased during the TGE_

### vestingTVLReached

```solidity
bool vestingTVLReached
```

Achievement of the pool's TVL as specified by the vesting settings

_A flag that irreversibly becomes True only if the pool for which the TGE is being conducted is able to reach or exceed its TVL value specified in the vesting parameters._

### lockupTVLReached

```solidity
bool lockupTVLReached
```

Achievement of the pool's TVL as specified by the lockup settings

_A flag that irreversibly becomes True only if the pool for which the TGE is being conducted is able to reach or exceed its TVL value specified in the lockup parameters._

### vestedBalanceOf

```solidity
mapping(address => uint256) vestedBalanceOf
```

A mapping that contains the amount of token units placed in vesting for a specific account

_The TGE event may continue to affect other components of the protocol even after its completion and status change to "Successful" and, less frequently, "Failed". Vesting can be set up to distribute tokens over a significant period of time after the end of the TGE.
    The vesting time calculation begins with the block ending the TGE. The calculation of uniform time intervals is carried out either from the end of the cliff period block or each subsequent interval is counted from the end of the previous block.
    The Vesting.unlockedBalanceOf method shows how much of the tokens for a particular TGE may be available for a claim by an address if that address has not requested a withdrawal of any amount of tokens. The Vesting.claimableBalanceOf method shows how many tokens in total within a particular TGE an address has already requested and successfully received for withdrawal. Subtracting the second value from the first using the same arguments for method calls will give you the number of tokens currently available for withdrawal by that address.
    Additionally, one of the conditions for unlocking tokens under the vesting program can be setting a cumulative pool balance of a specified amount. The compliance with this condition starts to be tracked by the backend, and as soon as the pool balance reaches or exceeds the specified amount even for a moment, the backend, on behalf of the wallet with the SERVICE_MANAGER role, sends a transaction to the vesting contract's setClaimTVLReached(address tge) method. Executing this transaction changes the value of the flag in the mapping mapping(address => bool) with a key equal to the TGE address. Raising this flag is irreversible, meaning that a one-time occurrence of the condition guarantees that the token request now depends only on the second part of the conditions related to the passage of time. The calculation of the cliff period and additional distribution intervals is not related to raising this flag, both conditions are independent of each other, not mandatory for simultaneous use in settings, but mandatory for simultaneous compliance if they were used in one set of settings.
    The vesting of one TGE does not affect the vesting of another TGE._

### totalVested

```solidity
uint256 totalVested
```

_Total number of tokens to be distributed within the vesting period_

### protocolFee

```solidity
uint256 protocolFee
```

Protocol fee at the time of TGE creation

_Since the protocol fee can be changed, the actual value at the time of contract deployment is fixed in the contract's memory to avoid dependencies on future states of the Service contract._

### isProtocolTokenFeeClaimed

```solidity
bool isProtocolTokenFeeClaimed
```

Protocol fee payment

_A flag that irreversibly becomes True after a successful transfer of the protocol fee to the address specified in the Service contract.
Used only for Governance Token Generation Event._

### totalProtocolFee

```solidity
uint256 totalProtocolFee
```

_Total number of token units that make up the protocol fee_

### vesting

```solidity
contract IVesting vesting
```

Vesting contract address

_The TGE contract works closely with the Vesting contract, with a separate instance being issued for each token generation event, while there is only one Vesting contract. Together, they contain the most comprehensive information about a user's purchases, tokens in reserve but not yet issued, and the conditions for locking and unlocking tokens. Moreover, the TGE contract has a token buyback function under specific conditions (see the "Redeem" section for more details).
    One TGE contract is used for the distribution of only one protocol token (the token contract address is specified when launching the TGE). At any given time, there can be only one active TGE for a single token._

### Purchased

```solidity
event Purchased(address buyer, uint256 amount)
```

_Event emitted upon successful purchase (or distribution if the token unit price is 0)_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| buyer | address | Address of the token recipient (buyer) |
| amount | uint256 | Number of token units acquired |

### ProtocolTokenFeeClaimed

```solidity
event ProtocolTokenFeeClaimed(address token, uint256 tokenFee)
```

_Event emitted after successful claiming of the protocol fee_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Address of the token contract |
| tokenFee | uint256 | Amount of tokens transferred as payment for the protocol fee |

### Redeemed

```solidity
event Redeemed(address account, uint256 refundValue)
```

_Event emitted upon redeeming tokens in case of a failed TGE._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Redeemer address |
| refundValue | uint256 | Refund value |

### FundsTransferred

```solidity
event FundsTransferred(uint256 amount)
```

_Event emitted upon transferring the raised funds to the pool contract address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | Amount of tokens/ETH transferred |

### constructor

```solidity
constructor() public
```

Contract constructor.

_This contract uses OpenZeppelin upgrades and has no need for a constructor function.
The constructor is replaced with an initializer function.
This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused._

### initialize

```solidity
function initialize(address _service, address _token, uint256 _tokenId, string _uri, struct ITGE.TGEInfo _info, uint256 _protocolFee) external
```

_Constructor function, can only be called once. In this method, settings for the TGE event are assigned, such as the contract of the token implemented using TGE, as well as the TGEInfo structure, which includes the parameters of purchase, vesting, and lockup. If no lockup or vesting conditions were set for the TVL value when creating the TGE, then the TVL achievement flag is set to true from the very beginning._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _service | address | Service contract |
| _token | address | TGE's token |
| _tokenId | uint256 | TGE's tokenId |
| _uri | string | Metadata URL for the ERC1155 token collection |
| _info | struct ITGE.TGEInfo | TGE parameters |
| _protocolFee | uint256 | Protocol fee snapshot |

### purchase

```solidity
function purchase(uint256 amount) external payable
```

This method is used for purchasing pool tokens.

_Any blockchain address can act as a buyer (TGE contract user) of tokens if the following conditions are met:
    - active event status (TGE.sol:state method returns the Active code value / "1")
    - the event is public (TGE.sol:info.Whitelist is empty) or the user's address is on the whitelist of addresses admitted to the event
    - the number of tokens purchased by the address is not less than TGE.sol:minPurchase (a common rule for all participants) and not more than TGE.sol:maxPurchaseOf(address) (calculated individually for each address)
    The TGEInfo of each such event also contains settings for the order in which token buyers receive their purchases and from when and to what extent they can start managing them.
    However, in any case, each address that made a purchase is mentioned in the TGE.sol:purchaseOf[] mapping. This record serves as proof of full payment for the purchase and confirmation of the buyer's status, even if as a result of the transaction, not a single token was credited to the buyer's address.
    After each purchase transaction, TGE.sol:purchase calculates what part of the purchase should be issued and immediately transferred to the buyer's balance, and what part should be left as a reserve (records, not issued tokens) in vesting until the prescribed settings for unlocking these tokens occur._

### redeem

```solidity
function redeem() external
```

Redeem acquired tokens with a refund of the spent assets.

_In the contract of an unsuccessful TGE, the redeem() method becomes active, allowing any token buyer to return them to the contract for subsequent burning. As a result of this transaction, the records of the user's purchases within this TGE will be zeroed out (or reduced), and the spent ETH or ERC20 tokens will be returned to their balance.
    If the buyer has a record of tokens locked under the vesting program for this TGE, they will not be burned, and the record of the vesting payment will simply be deleted. In this case, the transaction will also end with a transfer of the spent funds back to the buyer.
    The buyer cannot return more tokens than they purchased in this TGE; this contract keeps a record of the user's total purchase amount and reduces it with each call of the redeem token method. This can happen if the purchased tokens were distributed to other wallets, and after the end of the TGE, the buyer requests redemption after each transfer back to the purchase address._

### setLockupTVLReached

```solidity
function setLockupTVLReached() external
```

_Set the flag that the condition for achieving the pool balance of the value specified in the lockup settings is met. The action is irreversible._

### transferFunds

```solidity
function transferFunds() external
```

_This method is used to perform the following actions for a successful TGE after its completion: transfer funds collected from buyers in the form of info.unitofaccount tokens or ETH to the address of the pool to which TGE belongs (if info.price is 0, then this action is not performed), as well as for Governance tokens make a minting of the percentage of the amount of all user purchases specified in the Service.sol protocolTokenFee contract and transfer it to the address specified in the Service.sol contract in the protocolTreasury() getter. Can be executed only once. Any address can call the method._

### _claimProtocolTokenFee

```solidity
function _claimProtocolTokenFee() private
```

This method is used to transfer funds raised during the TGE to the address of the pool contract that conducted the TGE.

_The method can be called by any address. For safe execution, this method does not take any call arguments and only triggers for successful TGEs._

### maxPurchaseOf

```solidity
function maxPurchaseOf(address account) public view returns (uint256)
```

_Shows the maximum possible number of tokens to be purchased by a specific address, taking into account whether the user is on the white list and 0 what amount of purchases he made within this TGE._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Amount of tokens |

### state

```solidity
function state() public view returns (enum ITGE.State)
```

A state of a Token Generation Event

_A TGE event can be in one of the following states:
    - Active
    - Failed
    - Successful
    In TGEInfo, the three most important parameters used to determine the event's state are specified:
    - hardcap - the maximum number of tokens that can be distributed during the event (the value is stored considering the token's Decimals)
    - softcap - the minimum expected number of tokens that should be distributed during the event (the value is stored considering the token's Decimals)
    - duration - the duration of the event (the number of blocks since the TGE deployment transaction)
    A successful outcome of the event and the assignment of the "Successful" status to the TGE occurs if:
    - no fewer than duration blocks have passed since the TGE launch, and no fewer than softcap tokens have been acquired
    OR
    - 100% of the hardcap tokens have been acquired at any point during the event
    If no fewer than duration blocks have passed since the TGE launch and fewer than softcap tokens have been acquired, the event is considered "Failed".
    If fewer than 100% of the hardcap tokens have been acquired, but fewer than duration blocks have passed since the TGE launch, the event is considered "Active"._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum ITGE.State | State code |

### transferUnlocked

```solidity
function transferUnlocked() public view returns (bool)
```

The given getter shows whether the transfer method is available for tokens that were distributed using a specific TGE contract. If the lockup period is over or if the lockup was not provided for this TGE, the getter always returns true.

_In contrast to vesting, lockup contains a simplified system of conditions (no additional distribution spread over equal time intervals), affects tokens located in the contract address, and does not involve actions related to minting or burning tokens.
    To configure lockup in TGEInfo, only two settings are specified: "lockupDuration" and "lockupTVL" (pool balance). The lockup duration is counted from the TGE creation block.
    Lockup locks the transfer of tokens purchased during the TGE for a period equal to the lockupDuration blocks and does not allow unlocking until the pool balance reaches lockupTVL. The address can use these tokens for Governance activities; they are on the balance and counted as votes.
    Unlocking by TVL occurs with a transaction similar to vesting. The SERVICE_MANAGER address can send a setLockupTVLReached() transaction to the TGE contract, which irreversibly changes the value of this condition flag to "true".
    Vesting and lockup are completely parallel entities. Tokens can be unlocked under the lockup program but remain in vesting. The lockup of one TGE does not affect the lockup of another TGE._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool Is transfer available |

### lockedBalanceOf

```solidity
function lockedBalanceOf(address account) external view returns (uint256)
```

_Shows the number of TGE tokens blocked in this contract. If the lockup is completed or has not been assigned, the method returns 0 (all tokens on the address balance are available for transfer). If the lockup period is still active, then the difference between the tokens purchased by the user and those in the vesting is shown (both parameters are only for this TGE)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Account address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Locked balance |

### redeemableBalanceOf

```solidity
function redeemableBalanceOf(address account) external view returns (uint256)
```

_Shows the number of TGE tokens available for redeem for `account`_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Account address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Redeemable balance of the address |

### getTotalPurchasedValue

```solidity
function getTotalPurchasedValue() public view returns (uint256)
```

_The given getter shows how much info.unitofaccount was collected within this TGE. To do this, the amount of tokens purchased by all buyers is multiplied by info.price._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 Total value |

### getTotalVestedValue

```solidity
function getTotalVestedValue() public view returns (uint256)
```

_This getter shows the total value of all tokens that are in the vesting. Tokens that were transferred to user’s wallet addresses upon request for successful TGEs and that were burned as a result of user funds refund for unsuccessful TGEs are not taken into account._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 Total value |

### getUserWhitelist

```solidity
function getUserWhitelist() external view returns (address[])
```

_This method returns the full list of addresses allowed to participate in the TGE._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | address An array of whitelist addresses |

### isUserWhitelisted

```solidity
function isUserWhitelisted(address account) public view returns (bool)
```

_Checks if user is whitelisted._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | User address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | 'True' if the whitelist is empty (public TGE) or if the address is found in the whitelist, 'False' otherwise. |

### isERC1155TGE

```solidity
function isERC1155TGE() public view returns (bool)
```

_This method indicates whether this event was launched to implement ERC1155 tokens._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool Flag if ERC1155 TGE |

### getEnd

```solidity
function getEnd() external view returns (uint256)
```

_Returns the block number at which the event ends._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 Block number |

### getInfo

```solidity
function getInfo() external view returns (struct ITGE.TGEInfo)
```

This method returns the immutable settings with which the TGE was launched.

_The rules for conducting an event are defined in the TGEInfo structure, which is passed within the calldata when calling one of the TGEFactory contract functions responsible for launching the TGE. For more information about the structure, see the "Interfaces" section. The variables mentioned below should be understood as attributes of the TGEInfo structure.
    A TGE can be public or private. To make the event public, simply leave the whitelist empty.
    The TGE contract can act as an airdrop - a free token distribution. To do this, set the price value to zero.
    To create a DAO with a finite number of participants, each of whom should receive an equal share of tokens, you can set the whitelist when launching the TGE as a list of the participants' addresses, and set both minPurchase and maxPurchase equal to the expression (hardcap / number of participants). To make the pool obtain DAO status only if the distribution is successful under such conditions for all project participants, you can set the softcap value equal to the hardcap. With these settings, the company will become a DAO only if all the initial participants have an equal voting power._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct ITGE.TGEInfo | The settings in the form of a TGEInfo structure |

### getProtocolTokenFee

```solidity
function getProtocolTokenFee(uint256 amount) public view returns (uint256)
```

_This method returns the number of tokens that are currently due as protocol fees during the TGE._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The number of tokens |

### onlyState

```solidity
modifier onlyState(enum ITGE.State state_)
```

Modifier that allows the method to be called only if the TGE state is equal to the specified state.

### onlyWhitelistedUser

```solidity
modifier onlyWhitelistedUser()
```

Modifier that allows the method to be called only by an account that is whitelisted for the TGE or if the TGE is created as public.

### onlyManager

```solidity
modifier onlyManager()
```

Modifier that allows the method to be called only by an account that has the ADMIN role in the Service contract.

### whenPoolNotPaused

```solidity
modifier whenPoolNotPaused()
```

Modifier that allows the method to be called only if the pool associated with the event is not in a paused state.

## TGEFactory

Event emitted on creation of primary TGE.

_Deployment of a TGE can occur both within the execution of transactions prescribed by a proposal, and during the execution of a transaction initiated by the pool owner, who has not yet become a DAO._

### service

```solidity
contract IService service
```

Service contract address

### PrimaryTGECreated

```solidity
event PrimaryTGECreated(address pool, address tge, address token)
```

_Event emitted when the primary TGE contract is deployed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the pool for which the TGE is launched. |
| tge | address | Address of the deployed TGE contract. |
| token | address | Address of the token contract. |

### SecondaryTGECreated

```solidity
event SecondaryTGECreated(address pool, address tge, address token)
```

_Event emitted when a secondary TGE contract operating with ERC20 tokens is deployed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the pool for which the TGE is launched. |
| tge | address | Address of the deployed TGE contract. |
| token | address | Address of the ERC20 token contract. |

### SecondaryTGEERC1155Created

```solidity
event SecondaryTGEERC1155Created(address pool, address tge, address token, uint256 tokenId)
```

_Event emitted when a secondary TGE contract operating with ERC1155 tokens is * deployed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the pool for which the TGE is launched.* |
| tge | address | Address of the deployed TGE contract.* |
| token | address | Address of the ERC1155 token contract.* |
| tokenId | uint256 | Identifier of the ERC1155 token collection. |

### onlyPool

```solidity
modifier onlyPool()
```

Modifier that allows the method to be called only by the Pool contract.

### whenNotPaused

```solidity
modifier whenNotPaused()
```

Modifier that allows the method to be called only if the Service contract is not paused.

### constructor

```solidity
constructor() public
```

Contract constructor.

_This contract uses OpenZeppelin upgrades and has no need for a constructor function.
The constructor is replaced with an initializer function.
This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused._

### initialize

```solidity
function initialize(contract IService service_) external
```

Contract initializer

_This method replaces the constructor for upgradeable contracts. It also sets the address of the Service contract in the contract's storage._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| service_ | contract IService | The address of the Service contract. |

### createPrimaryTGE

```solidity
function createPrimaryTGE(address poolAddress, struct IToken.TokenInfo tokenInfo, struct ITGE.TGEInfo tgeInfo, string metadataURI, struct IGovernanceSettings.NewGovernanceSettings governanceSettings_, address[] secretary, address[] executor) external
```

_This method is used to launch the primary TGE of the Governance token. When launching such a TGE, a new Token contract is deployed with TokenType = "Governance". If this TGE is successful, it will no longer be possible to repeat such a launch, and the created token will irreversibly become the Governance token of the pool.
Simultaneously with contract deployment, Governance Settings and lists of secretaries and executors are set._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolAddress | address | Pool address. |
| tokenInfo | struct IToken.TokenInfo | New token parameters (token type, decimals & description are ignored) |
| tgeInfo | struct ITGE.TGEInfo | Pool TGE parameters |
| metadataURI | string | Metadata URI |
| governanceSettings_ | struct IGovernanceSettings.NewGovernanceSettings | Set of Governance settings |
| secretary | address[] | Secretary address |
| executor | address[] | Executor address |

### createSecondaryTGE

```solidity
function createSecondaryTGE(address token, struct ITGE.TGEInfo tgeInfo, struct IToken.TokenInfo tokenInfo, string metadataURI) external
```

_This method allows users to launch primary and secondary TGEs for Governance and Preference tokens deployed based on the ERC20 contract. The creation of a token occurs if the TGE involves the distribution of a previously nonexistent Preference token. Launch is only possible by executing a successful proposal._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | ERC20 token address for distribution in the TGE |
| tgeInfo | struct ITGE.TGEInfo | TGE parameters |
| tokenInfo | struct IToken.TokenInfo | Token parameters |
| metadataURI | string | Metadata URI |

### createSecondaryTGEERC1155

```solidity
function createSecondaryTGEERC1155(address token, uint256 tokenId, string uri, struct ITGE.TGEInfo tgeInfo, struct IToken.TokenInfo tokenInfo, string metadataURI) external
```

_This method launches a secondary TGE for a specified series of ERC1155 Preference tokens. If an unused series is being used, the maximum cap for this series is determined within this transaction. If no token address is specified, a new ERC1155 Preference token contract is deployed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | ERC1155 token address for distribution in the TGE |
| tokenId | uint256 | ERC1155 token collection address for distribution of units in the TGE |
| uri | string | Metadata URI according to the ERC1155 specification |
| tgeInfo | struct ITGE.TGEInfo | TGE parameters |
| tokenInfo | struct IToken.TokenInfo | Token parameters |
| metadataURI | string | Metadata URI |

### _createSecondaryTGE

```solidity
function _createSecondaryTGE(address token, uint256 tokenId, string uri, struct ITGE.TGEInfo tgeInfo, struct IToken.TokenInfo tokenInfo, string metadataURI) internal returns (address, contract ITGE)
```

### _createInitialPreferenceTGE

```solidity
function _createInitialPreferenceTGE(uint256 tokenId, string uri, struct ITGE.TGEInfo tgeInfo, struct IToken.TokenInfo tokenInfo, string metadataURI) internal returns (address, contract ITGE)
```

_This internal method implements the logic of launching a TGE for Preference tokens that do not yet have their own contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | ERC1155 token collection address for distribution of units in the TGE |
| uri | string | Metadata URI according to the ERC1155 specification |
| tgeInfo | struct ITGE.TGEInfo | TGE parameters |
| tokenInfo | struct IToken.TokenInfo | Token parameters |
| metadataURI | string | Metadata URI |

### _createTGE

```solidity
function _createTGE(string metadataURI, address pool) internal returns (contract ITGE tge)
```

_This method deploys the TGE contract and returns its address after creation._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| metadataURI | string | TGE metadata URI |
| pool | address | Pool address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | contract ITGE | TGE contract |

## Token

Tokens are the primary quantitative characteristic of all entities within the protocol. In addition to their inherent function as a unit of calculation, tokens can also be used as votes and as a unit indicating the degree of participation of an address in an off-chain or on-chain pool project. Tokens of any type can only be issued within the framework of a TGE (Token Generation Event), and by using vesting settings, such a TGE can divide the issuance of purchased or airdropped tokens into stages, as well as temporarily block the ability to transfer them from one address to another.

_An expanded ERC20 contract, based on which tokens of various types are issued. At the moment, the protocol provides for 2 types of tokens: Governance, which must be created simultaneously with the pool, existing for the pool only in the singular and participating in voting, and Preference, which may be several for one pool and which do not participate in voting in any way._

### service

```solidity
contract IService service
```

_Service contract address_

### pool

```solidity
address pool
```

_Pool contract address_

### tokenType

```solidity
enum IToken.TokenType tokenType
```

Token type code

_Code "1" - Governance Token is the main token of the pool, compatible with the ERC20 standard. One such token is equal to one vote. One pool can only have one contract of this type of token. When the primary TGE is launched, dedicated to the distribution of this type of token, the token is only a candidate for the Governance role.
    In case of a successful TGE, it remains the Governance token of the pool forever.
    In case of a failed TGE, it carries no weight and voting power for Governance procedures; another token can be appointed in its place through a repeated primary TGE. The cap is set once during the launch of the primary TGE.
    During each TGE, an additional issuance of Service:ProtocolTokenFee percent of the total volume of tokens distributed during the event takes place and is transferred to the balance of the Service:ProtocolTreasury address.
Code "2" - Preference Token is an additional pool token, compatible with the ERC20 standard. It does not have voting power. One pool can have multiple independent and non-interacting tokens of this type.
    In case of a successful TGE, it is recognized by the pool as a Preference token forever.
    In case of a failed TGE, the pool forgets about such a token, not recognizing it as a Preference token.
    The cap is set once during the launch of the primary TGE._

### description

```solidity
string description
```

_Preference token description, allows up to 5000 characters, for others - ""_

### tgeList

```solidity
address[] tgeList
```

All TGEs associated with this token

_A list of TGE contract addresses that have been launched to distribute this token. If any of the elements in the list have a "Successful" state, it means that the token is valid and used by the pool. If there are no such TGEs, the token can be considered unsuccessful, meaning it is detached from the pool._

### _decimals

```solidity
uint8 _decimals
```

Token decimals

_This parameter is mandatory for all ERC20 tokens and is set to 18 by default. It indicates the precision applied when calculating a particular token. It can also be said that 10 raised to the power of minus decimal is the minimum indivisible amount of the token._

### totalVested

```solidity
uint256 totalVested
```

_Total Vested tokens for all TGEs_

### tgeWithLockedTokensList

```solidity
address[] tgeWithLockedTokensList
```

_List of all TGEs with locked tokens_

### totalProtocolFeeReserved

```solidity
uint256 totalProtocolFeeReserved
```

_Total amount of tokens reserved for the minting protocol fee_

### constructor

```solidity
constructor() public
```

Contract constructor.

_This contract uses OpenZeppelin upgrades and has no need for a constructor function.
The constructor is replaced with an initializer function.
This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused._

### initialize

```solidity
function initialize(contract IService service_, address pool_, struct IToken.TokenInfo info, address primaryTGE_) external
```

_Token creation, can only be started once. At the same time, the TGE contract, which sells the created token, is necessarily simultaneously deployed and receives an entry in the Registry. For the Governance token, the Name field for the ERC20 standard is taken from the trademark of the Pool contract to which the deployed token belongs. For Preference tokens, you can set an arbitrary value of the Name field._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| service_ | contract IService | The address of the Service contract |
| pool_ | address | The address of the pool contract |
| info | struct IToken.TokenInfo | The token parameters, including its type, in the form of a structure described in the TokenInfo method |
| primaryTGE_ | address | The address of the primary TGE for this token |

### mint

```solidity
function mint(address to, uint256 amount) external
```

_Minting of new tokens. Only the TGE or Vesting contract can mint tokens, there is no other way to get an additional issue. If the user who is being minted does not have tokens, they are sent to delegation on his behalf._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address of the account for which new token units are being minted |
| amount | uint256 | The number of tokens being minted |

### burn

```solidity
function burn(address from, uint256 amount) external
```

_Method for burning tokens. It can be called by both the token owner and the TGE contract to burn returned tokens during redeeming._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address of the account |
| amount | uint256 | The amount of tokens |

### addTGE

```solidity
function addTGE(address tge) external
```

_This method adds the TGE contract address to the TGEList of this token._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | The TGE address |

### setTGEVestedTokens

```solidity
function setTGEVestedTokens(uint256 amount) external
```

_This method modifies the number of token units that are vested and reserved for claiming by users._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of tokens |

### setProtocolFeeReserved

```solidity
function setProtocolFeeReserved(uint256 amount) external
```

_This method modifies the number of token units that are reserved as protocol fee._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of tokens |

### decimals

```solidity
function decimals() public view returns (uint8)
```

_This method returns the precision level for the fractional parts of this token._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint8 | Decimals |

### cap

```solidity
function cap() public view returns (uint256)
```

_This method returns the maximum allowable token emission._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The number of tokens taking into account the Decimals parameter |

### symbol

```solidity
function symbol() public view returns (string)
```

_This method returns the short name of the token, its ticker for listing._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | A string with the name |

### unlockedBalanceOf

```solidity
function unlockedBalanceOf(address account) public view returns (uint256)
```

_The given getter returns the total balance of the address that is not locked for transfer, taking into account all the TGEs with which this token was distributed.
It is the difference between the actual balance of the account and its locked portion._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address of the account |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Unlocked balance of the account |

### isPrimaryTGESuccessful

```solidity
function isPrimaryTGESuccessful() external view returns (bool)
```

_This method indicates whether a successful TGE has been conducted for this token. To determine this, it is sufficient to check the first event from the list of all TGEs. If it ended in failure, then this token cannot be considered active for its pool._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool Is any TGE successful |

### getTGEList

```solidity
function getTGEList() external view returns (address[])
```

_This method returns the list of addresses of all TGE contracts ever deployed for this token._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | array An array of contract addresses |

### getTgeWithLockedTokensList

```solidity
function getTgeWithLockedTokensList() external view returns (address[])
```

_This method returns the list of addresses of all TGE contracts ever deployed for this token and having active token transfer restrictions._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | array An array of contract addresses |

### lastTGE

```solidity
function lastTGE() external view returns (address)
```

_This method returns the address of the last conducted TGE for this token. Sorting is based on the starting block of the TGE, not the ending block (i.e., even if an earlier TGE contract is still active and the most recent one by creation time has already ended, the method will still return the address of the most recent contract)._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The contract address |

### getTotalTGEVestedTokens

```solidity
function getTotalTGEVestedTokens() public view returns (uint256)
```

_This method returns the accumulated value stored in the contract's memory, which represents the number of token units that are in vesting at the time of the request._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The sum of tokens in vesting |

### getTotalProtocolFeeReserved

```solidity
function getTotalProtocolFeeReserved() public view returns (uint256)
```

_This method returns the accumulated value stored in the contract's memory, which represents the number of token units that are reserved and should be issued and sent as the contract's fee._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The sum of tokens for the fee |

### totalSupplyWithReserves

```solidity
function totalSupplyWithReserves() public view returns (uint256)
```

_This method calculates the total supply for the token taking into account the reserved but not yet issued units (for vesting and protocol fee)._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The sum of reserved tokens |

### isERC1155

```solidity
function isERC1155() public pure returns (bool)
```

### _transfer

```solidity
function _transfer(address from, address to, uint256 amount) internal
```

Overriding the transfer method of the ERC20 token contract.

_When tokens are being transferred, a check is performed to ensure that the sender's balance has a sufficient amount of tokens that are not locked up. This is a stricter condition compared to the normal balance check.
Each such transaction also triggers the check of all TGE contracts for the end of lockup and removes such contracts from the tgeWithLockedTokensList._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address of the sender |
| to | address | The address of the recipient |
| amount | uint256 | Amount of tokens |

### _afterTokenTransfer

```solidity
function _afterTokenTransfer(address from, address to, uint256 amount) internal
```

_Hook that is called after any transfer of tokens. This includes
minting and burning._

### transfer

```solidity
function transfer(address to, uint256 amount) public returns (bool)
```

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) public returns (bool)
```

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

Burning a specified amount of tokens that are held in the account's balance

_Burning a specified amount of units of the token from the specified account._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address from which tokens are deducted for destruction |
| amount | uint256 | The amount of tokens to be destroyed |

### updateTgeWithLockedTokensList

```solidity
function updateTgeWithLockedTokensList() private
```

Update the list of TGEs with locked tokens

_It is crucial to keep this list up to date to have accurate information at any given time on how much of their token balance each user can dispose of, taking into account the locks imposed by the TGEs in which the user participated._

### onlyPool

```solidity
modifier onlyPool()
```

Modifier that allows the method to be called only by the Pool contract.

### onlyTGEFactory

```solidity
modifier onlyTGEFactory()
```

Modifier that allows the method to be called only by the TGEFactory contract.

### onlyTGE

```solidity
modifier onlyTGE()
```

Modifier that allows the method to be called only by the TGE contract.

### onlyTGEOrVesting

```solidity
modifier onlyTGEOrVesting()
```

Modifier that allows the method to be called only by the TGE or Vesting contract.

### whenPoolNotPaused

```solidity
modifier whenPoolNotPaused()
```

Modifier that allows the method to be called only if the Pool contract is not paused.

## TokenERC1155

_An expanded ERC20 contract, based on which tokens of various types are issued. At the moment, the protocol provides for 2 types of tokens: Governance, which must be created simultaneously with the pool, existing for the pool only in the singular and participating in voting, and Preference, which may be several for one pool and which do not participate in voting in any way._

### service

```solidity
contract IService service
```

_The address of the Service contract_

### symbol

```solidity
string symbol
```

_The token symbol or ticker for listing_

### _tokenURIs

```solidity
mapping(uint256 => string) _tokenURIs
```

_Mapping storing the URI metadata for each collection of the token_

### cap

```solidity
mapping(uint256 => uint256) cap
```

_Mapping storing the maximum caps for each collection of ERC1155 token_

### lastTokenId

```solidity
uint256 lastTokenId
```

_The identifier (sequential number) of the token collection that was created last_

### pool

```solidity
address pool
```

_The address of the pool contract that owns the token_

### tokenType

```solidity
enum IToken.TokenType tokenType
```

The digital code of the token type

_In the current version, ERC1155 tokens can only have the code "2", which corresponds to the Preference token type._

### name

```solidity
string name
```

_Preference token name_

### description

```solidity
string description
```

_Preference token description, allows up to 5000 characters, for others - ""_

### tgeList

```solidity
mapping(uint256 => address[]) tgeList
```

All TGEs associated with this token

_A list of TGE contract addresses that have been launched to distribute collections of this token. The collection ID serves as the key for this mapping._

### totalVested

```solidity
mapping(uint256 => uint256) totalVested
```

_Mapping storing the amounts of tokens in vesting for each collection of this token_

### tgeWithLockedTokensList

```solidity
mapping(uint256 => address[]) tgeWithLockedTokensList
```

_Mapping storing lists of TGEs with active token lockups for each collection of this token_

### totalProtocolFeeReserved

```solidity
mapping(uint256 => uint256) totalProtocolFeeReserved
```

_Mapping storing the amounts of tokens reserved as protocol fees for each collection of this token_

### constructor

```solidity
constructor() public
```

Contract constructor.

_This contract uses OpenZeppelin upgrades and has no need for a constructor function.
The constructor is replaced with an initializer function.
This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused._

### initialize

```solidity
function initialize(contract IService _service, address _pool, struct IToken.TokenInfo _info, address _primaryTGE) external
```

_Token creation, can only be started once. At the same time, the TGE contract, which sells the created token, is necessarily simultaneously deployed and receives an entry in the Registry. For Preference tokens, you can set an arbitrary value of the Name field._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _service | contract IService | The address of the Service contract. |
| _pool | address | The address of the pool contract. |
| _info | struct IToken.TokenInfo | The parameters of the token, including its type, in the form of a structure described in the TokenInfo method. |
| _primaryTGE | address | The address of the primary TGE for this token. |

### mint

```solidity
function mint(address to, uint256 tokenId, uint256 amount) external
```

_Minting of new tokens. Only the TGE or Vesting contract can mint tokens, there is no other way to get an additional issue. If the user who is being minted does not have tokens, they are sent to delegation on his behalf._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address of the account for which new token units are being minted. |
| tokenId | uint256 | The token collection of the ERC1155 contract. |
| amount | uint256 | The amount of tokens being minted. |

### burn

```solidity
function burn(address from, uint256 tokenId, uint256 amount) public
```

_Method for burning tokens. It can be called by both token owners and TGE contracts to burn the returned tokens during redeeming._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The account address. |
| tokenId | uint256 | The token collection of the ERC1155 contract. |
| amount | uint256 | The amount of tokens being burned. |

### addTGE

```solidity
function addTGE(address tge, uint256 tokenId) external
```

_This method adds the TGE contract address to the TGEList of the specified token collection._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | The TGE address. |
| tokenId | uint256 | The token collection of the ERC1155 contract. |

### setTGEVestedTokens

```solidity
function setTGEVestedTokens(uint256 amount, uint256 tokenId) external
```

_This method modifies the number of token units that are vested and reserved for claiming by users._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of tokens. |
| tokenId | uint256 | The token collection of the ERC1155 contract. |

### setTokenIdCap

```solidity
function setTokenIdCap(uint256 _tokenId, uint256 _cap) external
```

_This method irreversibly sets the emission cap for each of the created token collections._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The token collection of the ERC1155 contract. |
| _cap | uint256 | The maximum emission cap in token units. |

### setProtocolFeeReserved

```solidity
function setProtocolFeeReserved(uint256 amount, uint256 tokenId) external
```

_This method modifies the number of token units that should be used as protocol fees._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of tokens. |
| tokenId | uint256 | The token collection of the ERC1155 contract. |

### setURI

```solidity
function setURI(uint256 tokenId, string tokenURI) external
```

_This method sets the metadata URI for each of the token collections._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The token collection of the ERC1155 contract. |
| tokenURI | string | The metadata URI. |

### decimals

```solidity
function decimals() public pure returns (uint8)
```

_This method is needed for compatibility with other protocol contracts to optimize algorithms. It always returns 0._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint8 | uint8 Decimals (always 0) |

### unlockedBalanceOf

```solidity
function unlockedBalanceOf(address account, uint256 tokenId) public view returns (uint256)
```

_The given getter returns the total balance of the address that is not locked for transfer, taking into account all the TGEs with which this token collection was distributed.
It calculates the difference between the actual balance of the account and its locked portion. The calculation is performed for the specified token collection._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account address. |
| tokenId | uint256 | The token collection of the ERC1155 contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The unlocked balance of the account. |

### isPrimaryTGESuccessful

```solidity
function isPrimaryTGESuccessful(uint256 _tokenId) external view returns (bool)
```

_This method indicates whether a successful TGE has been conducted for the given token collection. It is sufficient to check the first event from the list of all TGEs._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The token collection of the ERC1155 contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool Whether any TGE is successful. |

### getTGEList

```solidity
function getTGEList(uint256 tokenId) external view returns (address[])
```

_This method returns the list of addresses of all TGE contracts that have ever been deployed for the specified token collection._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The token collection of the ERC1155 contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | array An array of contract addresses. |

### getTgeWithLockedTokensList

```solidity
function getTgeWithLockedTokensList(uint256 tokenId) external view returns (address[])
```

_This method returns the list of addresses of all TGE contracts that have ever been deployed for the specified token collection and have active transfer restrictions._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The token collection of the ERC1155 contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | array An array of contract addresses. |

### lastTGE

```solidity
function lastTGE(uint256 tokenId) external view returns (address)
```

_This method returns the address of the latest TGE contract for the given token collection. Sorting is based on the block of the TGE start, not the end block (i.e., even if an earlier TGE contract is still active while the latest one by creation time has already ended, this method will return the address of the latest contract)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The token collection of the ERC1155 contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The TGE contract address. |

### getTotalTGEVestedTokens

```solidity
function getTotalTGEVestedTokens(uint256 tokenId) public view returns (uint256)
```

_This method returns the accumulated value stored in the contract's memory, which represents the number of token units from the specified collection that are vested at the time of the request._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The token collection of the ERC1155 contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The total number of vested tokens. |

### getTotalProtocolFeeReserved

```solidity
function getTotalProtocolFeeReserved(uint256 tokenId) public view returns (uint256)
```

_This method calculates the total supply for the token, taking into account the reserved but not yet minted token units (for vesting and protocol fee)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The token collection of the ERC1155 contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The total supply with reserves. |

### totalSupplyWithReserves

```solidity
function totalSupplyWithReserves(uint256 tokenId) public view returns (uint256)
```

_This method calculates the total supply for an ERC1155 token collection, taking into account the reserved but not yet minted token units (for vesting and protocol fee)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The token collection of the ERC1155 contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 The total supply of the token collection with reserves. |

### uri

```solidity
function uri(uint256 tokenId) public view returns (string)
```

_This getter allows retrieving the stored metadata URI for the specified ERC1155 token collection in the contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The token collection of the ERC1155 contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | uint256 The metadata URI for the collection. |

### isERC1155

```solidity
function isERC1155() external pure returns (bool)
```

### getURIList

```solidity
function getURIList(uint256 limit, uint256 offset) external view returns (string[])
```

### _transfer

```solidity
function _transfer(address from, address to, uint256 tokenId, uint256 amount) internal
```

Simple transfer for ERC1155 tokens.

_This method is used to transfer a specified amount of token units of the specified tokenId token collection of the ERC1155 type. The _beforeTokenTransfer validation scenario is applied before sending the tokens._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address of the sender. |
| to | address | The address of the recipient. |
| tokenId | uint256 | The token collection of the ERC1155 contract. |
| amount | uint256 | The amount of tokens. |

### transfer

```solidity
function transfer(address from, address to, uint256 tokenId, uint256 amount) external
```

### _beforeTokenTransfer

```solidity
function _beforeTokenTransfer(address operator, address from, address to, uint256[] ids, uint256[] amounts, bytes data) internal
```

Special hook for validating ERC1155 transfers.

_It is used to update the list of TGEs with an active lockup for the token units being transferred in an optimized way, while also checking the availability of unlocked balance for the transfer.
The set of parameters for this hook is comprehensive to be used for all ERC1155 methods related to token transfers between accounts._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The potential initiator of the TransferFrom transaction to whom the account entrusted their tokens. |
| from | address | The address of the sender. |
| to | address | The address of the recipient. |
| ids | uint256[] | The list of ERC1155 token collection IDs that are being transferred to another account. |
| amounts | uint256[] | The list of corresponding amounts of token units. |
| data | bytes | Additional calldata attached to the transaction. |

### _setURI

```solidity
function _setURI(uint256 tokenId, string tokenURI) internal
```

_Set the metadata URI source for the token collection._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The identifier of the ERC1155 token collection. |
| tokenURI | string | The URI string specifying the metadata source. |

### _updateTgeWithLockedTokensList

```solidity
function _updateTgeWithLockedTokensList(uint256 tokenId) private
```

Update the list of TGEs with locked tokens.

_It is crucial to keep this list up to date to have accurate information on how much of their token balance each user can dispose of, taking into account the locks imposed by TGEs in which the user participated.
Due to the nature of ERC1155, this method requires an additional argument specifying the token collection "tokenId". When transferring tokens of such collection, all TGEs related to the distribution of tokens from this collection will be checked._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | ERC1155 token collection identifier |

### onlyPool

```solidity
modifier onlyPool()
```

Modifier that allows the method to be called only by the Pool contract.

### onlyTGEFactory

```solidity
modifier onlyTGEFactory()
```

Modifier that allows the method to be called only by the TGEFactory contract.

### onlyTGE

```solidity
modifier onlyTGE()
```

Modifier that allows the method to be called only by the TGE contract.

### onlyTGEOrVesting

```solidity
modifier onlyTGEOrVesting()
```

Modifier that allows the method to be called only by the TGE or Vesting contract.

### whenPoolNotPaused

```solidity
modifier whenPoolNotPaused()
```

Modifier that allows the method to be called only if the Pool contract is not paused.

## TokenFactory

_A factory for token contracts, utilizing the Beacon Proxy pattern for creating new contracts. 
Each new contract is a "proxy" pointing to a "beacon" that stores the implementation logic.
This enables cheaper creation of new contracts and easier updating of all contracts at once.
The contract can also be upgraded, meaning the contract's logic can be replaced while retaining the same contract address and state variables._

### service

```solidity
contract IService service
```

Service contract

### onlyTGEFactory

```solidity
modifier onlyTGEFactory()
```

Modifier restricting function call to TGEFactory contract only

_Throws an exception if the caller is not the TGEFactory contract's address_

### constructor

```solidity
constructor() public
```

Contract constructor

_Disables the usage of initializers_

### initialize

```solidity
function initialize(contract IService service_) external
```

_Initializer function, can only be called once_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| service_ | contract IService | Address of the service contract |

### createToken

```solidity
function createToken(address pool, struct IToken.TokenInfo info, address primaryTGE) external returns (address token)
```

_Creates a token contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the pool |
| info | struct IToken.TokenInfo | Token information |
| primaryTGE | address | Address of the primary TGE |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token contract |

### createTokenERC1155

```solidity
function createTokenERC1155(address pool, struct IToken.TokenInfo info, address primaryTGE) external returns (address token)
```

_Creates a ERC1155 token contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | Address of the pool |
| info | struct IToken.TokenInfo | Token information |
| primaryTGE | address | Address of the primary TGE |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | Token contract |

## Vesting

The Vesting contract exists in a single instance and helps manage the vesting processes for all successful TGEs.

_The vesting setup is performed by passing a value as one of the fields of the TGEInfo structure called "vestingParams", which is a structure of IVesting.VestingParams. This set of settings allows you to specify:
    - what portion of the tokens will be released and directed to the buyer's wallet within the purchase transaction (using the TGE:purchase method);
    - what portion of the tokens will be available for claim after the cliff period and the duration of this period;
    - what percentage of the remaining tokens will be distributed equally over equal time intervals (as well as the number and duration of these intervals).
    Any of these fields can accept zero values, for example, you can set the distribution of tokens without a cliff period or, conversely, split the receipt of values into two parts (immediately and after some time), without specifying time intervals.
    @dev For each TGE, a list of Resolvers can be assigned, i.e., addresses that can stop the vesting program for a specific user. 
    The list of resolvers is immutable for each individual TGE and is set at the time of its launch (it can be stored in the proposal data for creating the TGE beforehand)._

### DENOM

```solidity
uint256 DENOM
```

Denominator for shares (such as thresholds)

_The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account._

### registry

```solidity
contract IRegistry registry
```

Registry contract address

### totalVested

```solidity
mapping(address => uint256) totalVested
```

Mapping that stores the total amount of tokens locked in vesting for each conducted TGE.

_Claiming tokens does not modify these data; they are used to calculate the amount of tokens that can be claimed by a specific address and to determine the total amount of tokens in vesting for a given account.
In the event of vesting cancellation for a specific address in any TGE, the value under the TGE address key is decreased by the full amount of tokens locked in vesting for that address._

### vested

```solidity
mapping(address => mapping(address => uint256)) vested
```

Mapping (tge, account) to amount of tokens vested to that account in TGE

_The vesting contract does not store tokens, but it contains records of which address is entitled to what amount of tokens for which TGE when the conditions set in the settings are met. This means that minting these tokens only occurs when the owner of the address requests them, prior to that, they are not included in totalSupply or balances. No record in Vesting can affect the vote calculation for Governance._

### claimed

```solidity
mapping(address => mapping(address => uint256)) claimed
```

Mapping that stores the total amount of tokens vested by a specific address for a given TGE.

_This parameter increases every time a successful transaction is made to the Claim method by an address._

### claimTVLReached

```solidity
mapping(address => bool) claimTVLReached
```

Mapping of flags indicating whether the TVL threshold set in the TGE conditions has been reached by the pool.

_It is one of the two conditions under which users can claim tokens reserved for them under the vesting program._

### resolved

```solidity
mapping(address => mapping(address => uint256)) resolved
```

Mapping that shows the amount of tokens that will not be transferred to the user during claiming due to the cancellation of vesting by a resolver.

### Vested

```solidity
event Vested(address tge, address account, uint256 amount)
```

_This event is emitted when new token units are vested due to token purchase._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE contract address |
| account | address | Account address |
| amount | uint256 | Amount of tokens vested for the account |

### Claimed

```solidity
event Claimed(address tge, address account, uint256 amount)
```

_This event is emitted for each token claiming by users._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE contract address |
| account | address | Account address that requested the token claiming |
| amount | uint256 | Amount of claimed tokens |

### Cancelled

```solidity
event Cancelled(address tge, address account, uint256 amount)
```

_This event is emitted when vesting is canceled for a specific account and TGE._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE contract address |
| account | address | Account address |
| amount | uint256 | Amount of tokens that will not be distributed to this address due to the cancellation |

### onlyTGE

```solidity
modifier onlyTGE()
```

Modifier allows the method to be called only by the TGE contract.

_This modifier is commonly used for calling the `vest` method, which registers the arrival of new token units into vesting as a result of a successful `purchase` method call in the TGE contract._

### onlyManager

```solidity
modifier onlyManager()
```

Modifier allows the method to be called only by an account that has the role of `SERVICE_MANAGER` in the Service contract.

_It restricts access to certain privileged actions that are reserved for the manager._

### onlyResolverOrTGE

```solidity
modifier onlyResolverOrTGE(address tge)
```

Modifier allows the method to be called only by an account whose address is specified in the list of resolvers for a given TGE.

### constructor

```solidity
constructor() public
```

Contract constructor.

_This contract uses OpenZeppelin upgrades and has no need for a constructor function.
The constructor is replaced with an initializer function.
This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused._

### initialize

```solidity
function initialize(contract IRegistry registry_) external
```

Contract initializer

_This method replaces the constructor for upgradeable contracts. Additionally, it sets the address of the Registry contract in the contract's storage._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| registry_ | contract IRegistry | Protocol registry address |

### vest

```solidity
function vest(address to, uint256 amount) external
```

Method for increasing the token balance in vesting for a specific TGE contract.

_This method is called only by the TGE contract and results in the creation of a new entry or an increase in the existing value in the vested mapping for the TGE key and the specified account. After this, the account is reserved the ability to mint and receive new token units in case the conditions specified in the vesting program for this TGE are met._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Account address that received the vested tokens |
| amount | uint256 | Amount of tokens to vest |

### setClaimTVLReached

```solidity
function setClaimTVLReached(address tge) external
```

Method for recording the occurrence of one of two conditions for token unlocking.

_This method can only be called by the address with the SERVICE_MANAGER role in the Service contract. It is a trusted way to load data into the source of truth about the TVL events achieved by the pool, as specified in the parameters of the vesting program._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE contract address |

### cancel

```solidity
function cancel(address tge, address account) external
```

Cancels vesting for the specified account and TGE contract addresses.

_Calling this method is only possible by the address specified in the resolvers list for the specific TGE, and it leads to resetting the token balance in vesting for the specified address, depriving it of the ability to make successful token claiming within the specified TGE._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE contract address |
| account | address | Account address |

### claim

```solidity
function claim(address tge) external
```

Method to issue and transfer unlocked tokens to the transaction sender's address.

_This method is executed with the specified TGE, for which the currently unlocked token volume is calculated. Calling the method results in the issuance and transfer of the entire calculated token volume to the sender's address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE contract address |

### vestingParams

```solidity
function vestingParams(address tge) public view returns (struct IVesting.VestingParams)
```

This method returns the vesting parameters specified for a specific TGE.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE contract address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct IVesting.VestingParams | VestingParams Vesting settings |

### validateParams

```solidity
function validateParams(struct IVesting.VestingParams params) public pure returns (bool)
```

This method validates the vesting program parameters proposed for use in the created TGE contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IVesting.VestingParams | Vesting program parameters |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | bool True if params are valid (reverts otherwise) |

### unlockedBalanceOf

```solidity
function unlockedBalanceOf(address tge, address account) public view returns (uint256)
```

This method returns the number of token units that have been unlocked for a specific account within the vesting program of a particular TGE.

_The returned value is the total sum of all quantities after all token unlocks that have occurred for this account within this TGE. In other words, claimed tokens are also part of this response._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE contract address |
| account | address | Account address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 Number of unlocked token units |

### claimableBalanceOf

```solidity
function claimableBalanceOf(address tge, address account) public view returns (uint256)
```

This method returns the currently available amount of token units that an account can claim within the specified TGE.

_This method takes into account previous claimings made by the account._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE contract address |
| account | address | Account address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uin256 Number of claimable token units |

### vestedBalanceOf

```solidity
function vestedBalanceOf(address tge, address account) public view returns (uint256)
```

This method shows the remaining tokens that are still vested for a given address.

_This method shows both still locked token units and already unlocked units ready for claiming._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tge | address | TGE contract address |
| account | address | Account address |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 Number of token units vested |

## GovernanceSettings

This module is responsible for storing, validating, and applying Governance settings, and it inherits from the GovernorProposals contract.

_This contract houses one of the most important structures of the protocol called GovernanceSettingsSet. It is used to represent various numerical parameters that universally and comprehensively describe the voting process. The module includes methods for formal data validation, which is proposed to be stored using this structure._

### DENOM

```solidity
uint256 DENOM
```

Denominator for shares (such as thresholds)

_The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account._

### proposalThreshold

```solidity
uint256 proposalThreshold
```

The minimum amount of votes required to create a proposal

_The proposal threshold is the number of votes (i.e., tokens delegated to an address) that are minimally required to create a proposal. When calling the Pool:propose method, the contract compares the number of votes of the address with this value, and if there are insufficient tokens in the delegation, the transaction ends with a revert.
    This value is stored in the Pool contract as an integer, taking into account the "Decimals" parameter of the Governance token. In the current version, for Governance tokens, this parameter is equal to 18. That is, the 18 rightmost digits of the value represent the fractional part of the number of tokens required to create a proposal.
    Each pool can set any ProposalThreshold value in the range from 0 to the maximum value allowed by the uint256 type. The setting is made in conjunction with changing other Governance Settings either by the Owner of the pool when launching the primary TGE or during the execution of "Governance Settings" proposal transactions._

### quorumThreshold

```solidity
uint256 quorumThreshold
```

The minimum amount of votes which need to participate in the proposal in order for the proposal to be considered valid, given as a percentage of all existing votes

_The quorum threshold is a percentage ratio stored in the Pool contract as an integer using the DENOM entry. It indicates the minimum share of all proposals[proposalId].vote.availableVotes that must be used in voting (regardless of whether the votes were "for" or "against", their sum matters) for the vote to be considered valid.
    Reaching the Quorum Threshold is one of several conditions required for a proposal to be accepted and executable.
    Each pool can set any QuorumThreshold value in the range from 0 to 100%. The setting is made in conjunction with changing other Governance Settings either by the Owner of the pool when launching the primary TGE or during the execution of "Governance Settings" proposal transactions._

### decisionThreshold

```solidity
uint256 decisionThreshold
```

The minimum amount of votes which are needed to approve the proposal, given as a percentage of all participating votes

_The decision threshold is a percentage ratio stored in the Pool contract as an integer using the DENOM entry. It indicates the minimum share of the votes cast by users that must be cast "for" a proposal during voting for a positive decision to be made.
    The sum of all votes cast by users during voting can be calculated using the formula:
        Pool:proposals[proposalId].vote.forVotes + Pool:proposals[proposalId].vote.againstVotes
    Reaching the Decision Threshold is one of several conditions required for a proposal to be accepted and executable.
    Each pool can set any DecisionThreshold value in the range from 0 to 100%. The setting is made in conjunction with changing other Governance Settings either by the Owner of the pool when launching the primary TGE or during the execution of "Governance Settings" proposal transactions._

### votingDuration

```solidity
uint256 votingDuration
```

The amount of time for which the proposal will remain active, given as the number of blocks which have elapsed since the creation of the proposal

### transferValueForDelay

```solidity
uint256 transferValueForDelay
```

The threshold value for a transaction which triggers the transaction execution delay

### executionDelays

```solidity
mapping(enum IRecordsRegistry.EventType => uint256) executionDelays
```

Returns transaction execution delay values for different proposal types

### votingStartDelay

```solidity
uint256 votingStartDelay
```

Delay before voting starts. In blocks

### __gap

```solidity
uint256[49] __gap
```

Storage gap (for future upgrades)

### GovernanceSettingsSet

```solidity
event GovernanceSettingsSet(uint256 proposalThreshold_, uint256 quorumThreshold_, uint256 decisionThreshold_, uint256 votingDuration_, uint256 transferValueForDelay_, uint256[4] executionDelays_, uint256 votingStartDelay_)
```

This event emitted only when the following values (governance settings) are set for a particular pool

_The emission of this event can coincide with the purchase of a pool, the launch of an initial TGE, or the execution of a transaction prescribed by a proposal with the GovernanceSettings type.GovernanceSettings_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalThreshold_ | uint256 | the proposal threshold (specified in token units with decimals taken into account) |
| quorumThreshold_ | uint256 | the quorum threshold (specified as a percentage) |
| decisionThreshold_ | uint256 | the decision threshold (specified as a percentage) |
| votingDuration_ | uint256 | the duration of the voting period (specified in blocks) |
| transferValueForDelay_ | uint256 | the minimum amount in USD for which a transfer from the pool wallet will be subject to a delay |
| executionDelays_ | uint256[4] | execution delays specified in blocks for different types of proposals |
| votingStartDelay_ | uint256 | the delay before voting starts for newly created proposals, specified in blocks |

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

This contract extends the functionality of the pool contract. If the pool has been granted DAO status, Governance tokens can be used as votes during the voting process for proposals created for the pool. With this architecture, the pool can invoke methods on behalf of itself provided by this module to execute transactions prescribed by proposals.

_This module provides additional methods for creating proposals, participating and observing the voting process, as well as safely and securely counting votes and executing decisions that have undergone voting._

### DENOM

```solidity
uint256 DENOM
```

Denominator for shares (such as thresholds)

_The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account._

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

### Proposal

```solidity
struct Proposal {
  struct IGovernor.ProposalCoreData core;
  struct Governor.ProposalVotingData vote;
  struct IGovernor.ProposalMetaData meta;
}
```

### proposals

```solidity
mapping(uint256 => struct Governor.Proposal) proposals
```

_In this mapping, the local identifier (specific to the pool's scope) is used as the key. The proposal is also registered in the Registry contract, where it is assigned a global number._

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

Mapping with the voting history.

_The account address is used as the first key, and the proposal number is used as the second key. The stored value for these keys is described by the Ballot type._

### lastProposalId

```solidity
uint256 lastProposalId
```

_Last proposal ID_

### ProposalCreated

```solidity
event ProposalCreated(uint256 proposalId, struct IGovernor.ProposalCoreData core, struct IGovernor.ProposalMetaData meta)
```

_Event emitted on proposal creation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |
| core | struct IGovernor.ProposalCoreData | Proposal core data |
| meta | struct IGovernor.ProposalMetaData | Proposal meta data |

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

This method returns the state of the specified proposal.

_Among the Governance Settings, there is a parameter called votingDuration, which contains the number of blocks for the duration of the vote, and a parameter called votingStartDelay, which contains the number of blocks for the delay of the vote's start relative to the block of the proposal's creation.
    The start and end blocks of the vote are placed in the Pool:proposals[proposalId] entry as vote.startBlock and vote.endBlock.
        vote.startBlock = block.number + votingStartDelay
        vote.endBlock = block.number + votingStartDelay + votingDuration
    The proposal status can be obtained from the Pool:proposalState(proposalId) method. It is formed by comparing the current block with the end block, as well as from proposals[proposalId].vote.executionState, which can store irreversible state flags "Canceled" or "Executed". This value is a numerical code for one of the proposal states, with all possible state types listed in Governor.sol:ProposalState.
    Before the endBlock occurs, the proposal has an Active status, but the ability to vote (using the castVote method in the Pool contract) only appears from the startBlock. This status means that the QuorumThreshold and/or DecisionThreshold have not yet been reached, and there is still a sufficient number of unused votes, the application of which can lead to either of the two results.
    When the endBlock occurs, the proposal is no longer Active. New votes are not accepted, and the state changes to:
    - Failed if the QuorumThreshold and/or DecisionThreshold were not met by the voters
    - Delayed if both thresholds were met.
    The Failed state is irreversible and means that the decision "for" was not made, i.e., the transactions prescribed by the proposal cannot be executed.
    The Delayed state means that the necessary number of votes has been cast "for" the proposal, but the transactions prescribed by the proposal can be executed only after proposals[proposalId].core.executionDelay blocks have passed.
    The AwaitingExecution state means that the necessary number of votes has been cast "for" the proposal, the delay has ended, and the transactions prescribed by the proposal can be executed right now.
    The Canceled state means that the address assigned the ADMIN role in the Service contract used the cancelProposal method of the Service contract and canceled the execution of the proposal. This method could work only if the proposal had an Active, Delayed, or AwaitingExecution state at the time of cancellation. This state is irreversible; the proposal permanently loses the ability to accept votes, and its transactions will not be executed.
    The Executed state means that the address assigned the SERVICE_MANAGER role in the Service contract, or the address assigned the Executor role in the Pool contract, or any address if no address was assigned the Executor role in the pool, used the executeProposal method in the Pool contract. This state means that all transactions prescribed by the proposal have been successfully executed._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Идентификатор Proposal. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | enum Governor.ProposalState | The state code using the ProposalState type. |

### getBallot

```solidity
function getBallot(address account, uint256 proposalId) public view returns (enum Governor.Ballot ballot, uint256 votes)
```

_This method is used to work with the voting history and returns the vote code according to the Ballot type made by the specified account in the specified proposal. Additionally, using the pastVotes snapshots, it provides information about the number of votes this account had during the specified voting._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | Account address. |
| proposalId | uint256 | Proposal identifier. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| ballot | enum Governor.Ballot | Vote type. |
| votes | uint256 | Number of votes cast. |

### _propose

```solidity
function _propose(struct IGovernor.ProposalCoreData core, struct IGovernor.ProposalMetaData meta, uint256 votingDuration, uint256 votingStartDelay) internal returns (uint256 proposalId)
```

_Creating a proposal and assigning it a unique identifier to store in the list of proposals in the Governor contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| core | struct IGovernor.ProposalCoreData | Proposal core data |
| meta | struct IGovernor.ProposalMetaData | Proposal meta data |
| votingDuration | uint256 | Voting duration in blocks |
| votingStartDelay | uint256 |  |

### _castVote

```solidity
function _castVote(uint256 proposalId, bool support) internal
```

Implementation of the voting method for the pool contract.

_This method includes a check that the proposal is still in the "Active" state and eligible for the user to cast their vote. Additionally, each invocation of this method results in an additional check for the conditions to prematurely end the voting._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID. |
| support | bool | "True" for a vote "in favor/for," "False" otherwise. |

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

The method checks whether it is possible to end the voting early with the result fixed. If a quorum was reached and so many votes were cast in favor that even if all other available votes were cast against, or if so many votes were cast against that it could not affect the result of the vote, this function will change set the end block of the proposal to the current block

_During the voting process, a situation may arise when such a number of votes have been cast "for" or "against" a proposal that no matter how the remaining votes are distributed, the outcome of the proposal will not change.
    This can occur in the following situations:
    - The sum of "for" votes and unused votes does not exceed the DecisionThreshold of the total number of votes allowed in the voting process (occurs when there are so many "against" votes that even using the remaining votes in favor of the proposal will not allow overcoming the DecisionThreshold).
    - The number of "for" votes is no less than the DecisionThreshold of the total number of votes allowed in the voting process (occurs when there are so many "for" votes that even if all the remaining unused votes are cast "against", the proposal will still be considered accepted).
    Both of these conditions trigger ONLY when the QuorumThreshold is reached simultaneously.
    In such cases, further voting and waiting become pointless and meaningless. No subsequent vote can influence the outcome of the voting to change.
    Therefore, an additional check for triggering the conditions described above has been added to the Pool:castVote method. If the vote can be safely terminated early, the proposals[proposalId].vote.endBlock is changed to the current one during the method's execution.
    This means that the state of the proposal ceases to be Active and should change to Failed or Delayed._

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

### shareOvercome

```solidity
function shareOvercome(uint256 amount, uint256 total, uint256 share) internal pure returns (bool)
```

_Checks if `amount` divided by `total` overcomes `share`_

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

_Hook called after a proposal is created_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposalId | uint256 | Proposal ID |

### _getBlockTotalVotes

```solidity
function _getBlockTotalVotes(uint256 blocknumber) internal view virtual returns (uint256)
```

_Function that returns the total amount of votes in the pool in block_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| blocknumber | uint256 | block number |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Total amount of votes |

### _getPastVotes

```solidity
function _getPastVotes(address account, uint256 blockNumber) internal view virtual returns (uint256)
```

_Function that returns the amount of votes for a client adrress at any given block_

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

_Function that set last ProposalId for a client address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposer | address | Proposer's address |
| proposalId | uint256 | Proposal id |

## GovernorProposals

Contract for tracking and typing the created proposals.

_The final implementation of the voting logic is placed in this module, which inherits from the Governor contract and is inherited by pool contracts._

### service

```solidity
contract IService service
```

_The address of the Service contract._

### lastProposalIdByType

```solidity
mapping(uint256 => uint256) lastProposalIdByType
```

_last Proposal Id By Type for state checking_

### ProposalType

```solidity
enum ProposalType {
  Transfer,
  TGE,
  GovernanceSettings
}
```

### __gap

```solidity
uint256[49] __gap
```

Storage gap (for future upgrades)

## ICustomProposal

## IInvoice

These structures are used to describe an instance of an invoice.

_The storage of invoices is managed in Invoice.sol in the `invoices` variable._

### InvoiceCore

```solidity
struct InvoiceCore {
  uint256 amount;
  address unitOfAccount;
  uint256 expirationBlock;
  string description;
  address[] whitelist;
}
```

### InvoiceInfo

```solidity
struct InvoiceInfo {
  struct IInvoice.InvoiceCore core;
  uint256 invoiceId;
  address createdBy;
  bool isPaid;
  bool isCanceled;
}
```

### InvoiceState

```solidity
enum InvoiceState {
  None,
  Active,
  Paid,
  Expired,
  Canceled
}
```

### createInvoice

```solidity
function createInvoice(address pool, struct IInvoice.InvoiceCore core) external
```

### payInvoice

```solidity
function payInvoice(address pool, uint256 invoiceId) external payable
```

### cancelInvoice

```solidity
function cancelInvoice(address pool, uint256 invoiceId) external
```

### setInvoiceCanceled

```solidity
function setInvoiceCanceled(address pool, uint256 invoiceId) external
```

## IPausable

### paused

```solidity
function paused() external view returns (bool)
```

## IPool

### initialize

```solidity
function initialize(struct ICompaniesRegistry.CompanyInfo companyInfo_) external
```

### setNewOwnerWithSettings

```solidity
function setNewOwnerWithSettings(address owner_, string trademark_, struct IGovernanceSettings.NewGovernanceSettings governanceSettings_) external
```

### propose

```solidity
function propose(address proposer, uint256 proposalType, struct IGovernor.ProposalCoreData core, struct IGovernor.ProposalMetaData meta) external returns (uint256 proposalId)
```

### setToken

```solidity
function setToken(address token_, enum IToken.TokenType tokenType_) external
```

### setProposalIdToTGE

```solidity
function setProposalIdToTGE(address tge) external
```

### cancelProposal

```solidity
function cancelProposal(uint256 proposalId) external
```

### setSettings

```solidity
function setSettings(struct IGovernanceSettings.NewGovernanceSettings governanceSettings_, address[] secretary, address[] executor) external
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

### getGovernanceToken

```solidity
function getGovernanceToken() external view returns (contract IToken)
```

### tokenExists

```solidity
function tokenExists(contract IToken token_) external view returns (bool)
```

### tokenTypeByAddress

```solidity
function tokenTypeByAddress(address token_) external view returns (enum IToken.TokenType)
```

### isValidProposer

```solidity
function isValidProposer(address account) external view returns (bool)
```

### isPoolSecretary

```solidity
function isPoolSecretary(address account) external view returns (bool)
```

### isLastProposalIdByTypeActive

```solidity
function isLastProposalIdByTypeActive(uint256 type_) external view returns (bool)
```

### validateGovernanceSettings

```solidity
function validateGovernanceSettings(struct IGovernanceSettings.NewGovernanceSettings settings) external pure
```

### getPoolSecretary

```solidity
function getPoolSecretary() external view returns (address[])
```

### getPoolExecutor

```solidity
function getPoolExecutor() external view returns (address[])
```

### setCompanyInfo

```solidity
function setCompanyInfo(uint256 _jurisdiction, uint256 _entityType, string _ein, string _dateOfIncorporation, string _OAuri) external
```

### castVote

```solidity
function castVote(uint256 proposalId, bool support) external
```

### executeProposal

```solidity
function executeProposal(uint256 proposalId) external
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

### createPool

```solidity
function createPool(struct ICompaniesRegistry.CompanyInfo companyInfo) external
```

### addProposal

```solidity
function addProposal(uint256 proposalId) external
```

### addEvent

```solidity
function addEvent(enum IRecordsRegistry.EventType eventType, uint256 proposalId, string metaHash) external
```

### setProtocolCollectedFee

```solidity
function setProtocolCollectedFee(address _token, uint256 _protocolTokenFee) external
```

### registry

```solidity
function registry() external view returns (contract IRegistry)
```

### vesting

```solidity
function vesting() external view returns (contract IVesting)
```

### tokenFactory

```solidity
function tokenFactory() external view returns (contract ITokenFactory)
```

### tgeFactory

```solidity
function tgeFactory() external view returns (contract ITGEFactory)
```

### invoice

```solidity
function invoice() external view returns (contract IInvoice)
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

### getProtocolCollectedFee

```solidity
function getProtocolCollectedFee(address token_) external view returns (uint256)
```

### poolBeacon

```solidity
function poolBeacon() external view returns (address)
```

### tgeBeacon

```solidity
function tgeBeacon() external view returns (address)
```

### tokenBeacon

```solidity
function tokenBeacon() external view returns (address)
```

### tokenERC1155Beacon

```solidity
function tokenERC1155Beacon() external view returns (address)
```

### customProposal

```solidity
function customProposal() external view returns (contract ICustomProposal)
```

### validateTGEInfo

```solidity
function validateTGEInfo(struct ITGE.TGEInfo info, uint256 cap, uint256 totalSupply, enum IToken.TokenType tokenType) external view
```

### getPoolAddress

```solidity
function getPoolAddress(struct ICompaniesRegistry.CompanyInfo info) external view returns (address)
```

### paused

```solidity
function paused() external view returns (bool)
```

### addInvoiceEvent

```solidity
function addInvoiceEvent(address pool, uint256 invoiceId) external returns (uint256)
```

### purchasePool

```solidity
function purchasePool(uint256 jurisdiction, uint256 entityType, string trademark, struct IGovernanceSettings.NewGovernanceSettings governanceSettings) external payable
```

### transferPurchasedPoolByService

```solidity
function transferPurchasedPoolByService(address newowner, uint256 jurisdiction, uint256 entityType, string trademark, struct IGovernanceSettings.NewGovernanceSettings governanceSettings) external
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
  uint256 duration;
  struct IVesting.VestingParams vestingParams;
  address[] userWhitelist;
  address unitOfAccount;
  uint256 lockupDuration;
  uint256 lockupTVL;
}
```

### initialize

```solidity
function initialize(address _service, address _token, uint256 _tokenId, string _uri, struct ITGE.TGEInfo _info, uint256 _protocolFee) external
```

### State

```solidity
enum State {
  Active,
  Failed,
  Successful
}
```

### token

```solidity
function token() external view returns (address)
```

### tokenId

```solidity
function tokenId() external view returns (uint256)
```

### state

```solidity
function state() external view returns (enum ITGE.State)
```

### getInfo

```solidity
function getInfo() external view returns (struct ITGE.TGEInfo)
```

### transferUnlocked

```solidity
function transferUnlocked() external view returns (bool)
```

### purchaseOf

```solidity
function purchaseOf(address user) external view returns (uint256)
```

### redeemableBalanceOf

```solidity
function redeemableBalanceOf(address user) external view returns (uint256)
```

### lockedBalanceOf

```solidity
function lockedBalanceOf(address account) external view returns (uint256)
```

### getEnd

```solidity
function getEnd() external view returns (uint256)
```

### totalPurchased

```solidity
function totalPurchased() external view returns (uint256)
```

### isERC1155TGE

```solidity
function isERC1155TGE() external view returns (bool)
```

### purchase

```solidity
function purchase(uint256 amount) external payable
```

### transferFunds

```solidity
function transferFunds() external
```

## ITGEFactory

### createSecondaryTGE

```solidity
function createSecondaryTGE(address token, struct ITGE.TGEInfo tgeInfo, struct IToken.TokenInfo tokenInfo, string metadataURI) external
```

### createSecondaryTGEERC1155

```solidity
function createSecondaryTGEERC1155(address token, uint256 tokenId, string uri, struct ITGE.TGEInfo tgeInfo, struct IToken.TokenInfo tokenInfo, string metadataURI) external
```

### createPrimaryTGE

```solidity
function createPrimaryTGE(address poolAddress, struct IToken.TokenInfo tokenInfo, struct ITGE.TGEInfo tgeInfo, string metadataURI, struct IGovernanceSettings.NewGovernanceSettings governanceSettings_, address[] secretary, address[] executor) external
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
function initialize(contract IService service_, address pool_, struct IToken.TokenInfo info, address primaryTGE_) external
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

### setTGEVestedTokens

```solidity
function setTGEVestedTokens(uint256 amount) external
```

### setProtocolFeeReserved

```solidity
function setProtocolFeeReserved(uint256 amount) external
```

### getTotalTGEVestedTokens

```solidity
function getTotalTGEVestedTokens() external view returns (uint256)
```

### getTotalProtocolFeeReserved

```solidity
function getTotalProtocolFeeReserved() external view returns (uint256)
```

### totalSupplyWithReserves

```solidity
function totalSupplyWithReserves() external view returns (uint256)
```

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 amount) external returns (bool)
```

_Moves `amount` tokens from `from` to `to` using the
allowance mechanism. `amount` is then deducted from the caller's
allowance.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event._

### transfer

```solidity
function transfer(address to, uint256 amount) external returns (bool)
```

_Moves `amount` tokens from the caller's account to `to`.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event._

## ITokenERC1155

### initialize

```solidity
function initialize(contract IService service_, address pool_, struct IToken.TokenInfo info, address primaryTGE_) external
```

### mint

```solidity
function mint(address to, uint256 tokenId, uint256 amount) external
```

### burn

```solidity
function burn(address from, uint256 tokenId, uint256 amount) external
```

### cap

```solidity
function cap(uint256 tokenId) external view returns (uint256)
```

### unlockedBalanceOf

```solidity
function unlockedBalanceOf(address account, uint256 tokenId) external view returns (uint256)
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
function lastTGE(uint256 tokenId) external view returns (address)
```

### getTGEList

```solidity
function getTGEList(uint256 tokenId) external view returns (address[])
```

### isPrimaryTGESuccessful

```solidity
function isPrimaryTGESuccessful(uint256 tokenId) external view returns (bool)
```

### addTGE

```solidity
function addTGE(address tge, uint256 tokenId) external
```

### setTGEVestedTokens

```solidity
function setTGEVestedTokens(uint256 amount, uint256 tokenId) external
```

### setProtocolFeeReserved

```solidity
function setProtocolFeeReserved(uint256 amount, uint256 tokenId) external
```

### getTotalTGEVestedTokens

```solidity
function getTotalTGEVestedTokens(uint256 tokenId) external view returns (uint256)
```

### getTotalProtocolFeeReserved

```solidity
function getTotalProtocolFeeReserved(uint256 tokenId) external view returns (uint256)
```

### totalSupplyWithReserves

```solidity
function totalSupplyWithReserves(uint256 tokenId) external view returns (uint256)
```

### setURI

```solidity
function setURI(uint256 tokenId, string tokenURI) external
```

### setTokenIdCap

```solidity
function setTokenIdCap(uint256 _tokenId, uint256 _cap) external
```

### transfer

```solidity
function transfer(address from, address to, uint256 tokenId, uint256 amount) external
```

## ITokenFactory

### createToken

```solidity
function createToken(address pool, struct IToken.TokenInfo info, address primaryTGE) external returns (address token)
```

### createTokenERC1155

```solidity
function createTokenERC1155(address pool, struct IToken.TokenInfo info, address primaryTGE) external returns (address token)
```

## IVesting

### VestingParams

```solidity
struct VestingParams {
  uint256 vestedShare;
  uint256 cliff;
  uint256 cliffShare;
  uint256 spans;
  uint256 spanDuration;
  uint256 spanShare;
  uint256 claimTVL;
  address[] resolvers;
}
```

### vest

```solidity
function vest(address to, uint256 amount) external
```

### cancel

```solidity
function cancel(address tge, address account) external
```

### validateParams

```solidity
function validateParams(struct IVesting.VestingParams params) external pure returns (bool)
```

### vested

```solidity
function vested(address tge, address account) external view returns (uint256)
```

### totalVested

```solidity
function totalVested(address tge) external view returns (uint256)
```

### vestedBalanceOf

```solidity
function vestedBalanceOf(address tge, address account) external view returns (uint256)
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
  uint256 votingStartDelay;
}
```

### setGovernanceSettings

```solidity
function setGovernanceSettings(struct IGovernanceSettings.NewGovernanceSettings settings) external
```

## IGovernor

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

### ProposalMetaData

```solidity
struct ProposalMetaData {
  enum IRecordsRegistry.EventType proposalType;
  string description;
  string metaHash;
}
```

### proposalState

```solidity
function proposalState(uint256 proposalId) external view returns (uint256 state)
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

### createCompany

```solidity
function createCompany(struct ICompaniesRegistry.CompanyInfo info) external
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

### service

```solidity
function service() external view returns (contract IService)
```

### COMPANIES_MANAGER_ROLE

```solidity
function COMPANIES_MANAGER_ROLE() external view returns (bytes32)
```

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```

### log

```solidity
function log(address sender, address receiver, uint256 value, bytes data) external
```

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

### WRONG_TOKEN_ADDRESS

```solidity
string WRONG_TOKEN_ADDRESS
```

### GOVERNANCE_TOKEN_EXISTS

```solidity
string GOVERNANCE_TOKEN_EXISTS
```

### THRESHOLD_NOT_REACHED

```solidity
string THRESHOLD_NOT_REACHED
```

### UNSUPPORTED_TOKEN_TYPE

```solidity
string UNSUPPORTED_TOKEN_TYPE
```

### ALREADY_VOTED

```solidity
string ALREADY_VOTED
```

### ZERO_VOTES

```solidity
string ZERO_VOTES
```

### ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS

```solidity
string ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS
```

### EMPTY_ADDRESS

```solidity
string EMPTY_ADDRESS
```

### NOT_VALID_PROPOSER

```solidity
string NOT_VALID_PROPOSER
```

### SHARES_SUM_EXCEEDS_ONE

```solidity
string SHARES_SUM_EXCEEDS_ONE
```

### NOT_RESOLVER

```solidity
string NOT_RESOLVER
```

### NOT_REGISTRY

```solidity
string NOT_REGISTRY
```

### INVALID_TARGET

```solidity
string INVALID_TARGET
```

### NOT_TGE_FACTORY

```solidity
string NOT_TGE_FACTORY
```

### WRONG_AMOUNT

```solidity
string WRONG_AMOUNT
```

### WRONG_BLOCK_NUMBER

```solidity
string WRONG_BLOCK_NUMBER
```

### NOT_VALID_EXECUTOR

```solidity
string NOT_VALID_EXECUTOR
```

### POOL_PAUSED

```solidity
string POOL_PAUSED
```

### NOT_INVOICE_MANAGER

```solidity
string NOT_INVOICE_MANAGER
```

### WRONG_RESOLVER

```solidity
string WRONG_RESOLVER
```

## CompaniesRegistry

This contract is a section of the Registry contract designed for storing and manipulating companies listed for sale.

_With the help of this contract, one can find out the number of companies available for purchase in a specific jurisdiction and their corresponding prices. Here, an isolated but still dependent role-based model based on Access Control from OZ is implemented, with the contract Service playing a crucial role._

### COMPANIES_MANAGER_ROLE

```solidity
bytes32 COMPANIES_MANAGER_ROLE
```

Hash code for the COMPANIES_MANAGER role in the OpenZeppelin (OZ) Access Control model.

_This role is intended for working with the showcase of companies available for purchase and can also add and modify the link to the organization's charter. It operates only within the Registry contract through a separate AccessControl model from OpenZeppelin with standard methods: grantRole, revokeRole, setRole.
    Methods:
    - CompaniesRegistry.sol:createCompany(CompanyInfo calldata info) - creating a company with specified immutable data and its price in ETH, deploying the contract with a temporary owner in the form of the Registry contract proxy address. After calling such a method, the company immediately becomes available for purchase.
    - CompaniesRegistry.sol:deleteCompany(uint256 jurisdiction, uint256 entityType, uint256 id) - deleting a company record (removing it from sale without the possibility of recovery).
    - CompaniesRegistry.sol:updateCompanyFee(uint256 jurisdiction, uint256 entityType, uint256 id, uint256 fee) - changing the price of an unsold company (prices are set in ETH).
    - Pool.sol:setOAUrl(string memory _uri) - changing the link to the pool's operating agreement.
    Storage, assignment, and revocation of the role are carried out using the standard methods of the AccessControl model from OpenZeppelin: grantRole, revokeRole, setRole. The holder of the standard ADMIN_ROLE of this contract can manage this role (by default - the address that deployed the contract)._

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

_An event emitted when a manager creates a new company. After this event, the company immediately becomes available for purchase._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| index | uint256 | Company list index. |
| poolAddress | address | The contract pool address computed based on the bytecode and initial arguments. |

### CompanyDeleted

```solidity
event CompanyDeleted(uint256 metadataIndex)
```

_An event emitted when a company is delisted from sale. This is one of the mechanisms to modify legal information regarding the company._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| metadataIndex | uint256 | Company metadata index. |

### CompanyFeeUpdated

```solidity
event CompanyFeeUpdated(uint256 jurisdiction, uint256 entityType, uint256 id, uint256 fee)
```

_The event is issued when the manager changes the price of an already created company ready for purchase by the client._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | The digital code of the jurisdiction. |
| entityType | uint256 | The digital code of the organization type. |
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

Lock company record

_Booking the company for the buyer. During the acquisition of a company, this method searches for a free company at the request of the client (jurisdiction and type of organization), if such exist in the company’s storage reserve, then the method selects the last of the added companies, extracts its record data and sends it as a response for further work of the Service contract, removes its record from the Registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | Цифровой код юрисдикции |
| entityType | uint256 | Цифровой код типа организакции |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| info | struct ICompaniesRegistry.CompanyInfo | Company info |

### deleteCompany

```solidity
function deleteCompany(uint256 jurisdiction, uint256 entityType, uint256 id) external
```

_This method removes a record from the queue of created companies._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | The digital code of the jurisdiction. |
| entityType | uint256 | The digital code of the organization type. |
| id | uint256 | Queue index. |

### updateCompanyFee

```solidity
function updateCompanyFee(uint256 jurisdiction, uint256 entityType, uint256 id, uint256 fee) external
```

_The method that the manager uses to change the value of the company already added earlier in the Registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | The digital code of the jurisdiction. |
| entityType | uint256 | The digital code of the organization type. |
| id | uint256 | Queue index. @ param fee Fee to update. |
| fee | uint256 |  |

### companyAvailable

```solidity
function companyAvailable(uint256 jurisdiction, uint256 entityType) external view returns (bool)
```

_This view method is designed to find out whether there is at least one company available for purchase for the jurisdiction and type of organization selected by the user._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | The digital code of the jurisdiction. |
| entityType | uint256 | The digital code of the organization type. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | "True" if at least one company is available |

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

_This method allows obtaining all the data of a company, including its legal data, that is still available for sale._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | The digital code of the jurisdiction. |
| entityType | uint256 | The digital code of the organization type. |
| ein | string | The government registration number. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct ICompaniesRegistry.CompanyInfo | CompanyInfo The company data. |

### getAvailableCompanyAddress

```solidity
function getAvailableCompanyAddress(uint256 jurisdiction, uint256 entityType) external view returns (address)
```

_This method allows obtaining the contract address of a company that is available for sale and meets the conditions based on its jurisdiction and entity type._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| jurisdiction | uint256 | The digital code of the jurisdiction. |
| entityType | uint256 | The digital code of the organization type. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address The contract pool address. |

### setCompanyInfoForPool

```solidity
function setCompanyInfoForPool(contract IPool pool, uint256 _jurisdiction, uint256 _entityType, string _ein, string _dateOfIncorporation, string _OAuri) external
```

Method for replacing the reference to the Operating Agreement and legal data of a company in the contract's memory.

_This is a special method for the manager to service contracts of already acquired companies. To correct data in a company that has not been acquired yet, the record should be deleted and a new one created._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | contract IPool | The contract pool address. |
| _jurisdiction | uint256 | The digital code of the jurisdiction. |
| _entityType | uint256 | The digital code of the organization type. |
| _ein | string | The government registration number. |
| _dateOfIncorporation | string | The date of incorporation. |
| _OAuri | string | Operating Agreement URL. |

## RecordsRegistry

@title Registry Contract
 @notice This contract complements the Registry and serves as a storage or all entities created by users of the protocol.

_Unlike the Companies Registry, this contract is managed solely by other protocol contracts without operator intervention, and logs all deployed contracts and their associated events._

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

### setGlobalProposalId

```solidity
function setGlobalProposalId(address pool, uint256 proposalId, uint256 globalProposalId) internal virtual
```

### typeOf

```solidity
function typeOf(address addr) public view returns (enum IRecordsRegistry.ContractType)
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

## RegistryBase

The core contract for the Registry contracts.

_This abstract contract is inherited by the Registry contract and contains functions and modifiers that could be applied to all contracts in this section._

### service

```solidity
address service
```

_The address of the Service contract._

### onlyService

```solidity
modifier onlyService()
```

Modifier that allows calling the method only from the Service contract.

### onlyServiceOrFactory

```solidity
modifier onlyServiceOrFactory()
```

Modifier that allows calling the method only from the Service, TGEFactory, and TokenFactory contracts.

### __RegistryBase_init

```solidity
function __RegistryBase_init() internal
```

_This method is executed during deployment or upgrade of the contract to set the contract initiator as the contract administrator. Without binding from the Service contract, this method cannot provide unauthorized access in any way._

### setService

```solidity
function setService(address service_) external
```

_This method is executed during deployment and upgrade of the contract to link the main protocol contract with the Registry data storage by storing the address of the Service contract._

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

## GovernanceToken

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize() public
```

### snapshot

```solidity
function snapshot() public
```

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### mint

```solidity
function mint(address to, uint256 amount) public
```

### _beforeTokenTransfer

```solidity
function _beforeTokenTransfer(address from, address to, uint256 amount) internal
```

### _afterTokenTransfer

```solidity
function _afterTokenTransfer(address from, address to, uint256 amount) internal
```

### _mint

```solidity
function _mint(address to, uint256 amount) internal
```

### _burn

```solidity
function _burn(address account, uint256 amount) internal
```

