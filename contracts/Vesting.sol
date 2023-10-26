// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./libraries/ExceptionsLibrary.sol";
import "./interfaces/registry/IRegistry.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IVesting.sol";
import "./utils/CustomContext.sol";
    /**
    * @title Vesting contract
    * @notice The Vesting contract exists in a single instance and helps manage the vesting processes for all successful TGEs.
    * @dev The vesting setup is performed by passing a value as one of the fields of the TGEInfo structure called "vestingParams", which is a structure of IVesting.VestingParams. This set of settings allows you to specify:
    - what portion of the tokens will be released and directed to the buyer's wallet within the purchase transaction (using the TGE:purchase method);
    - what portion of the tokens will be available for claim after the cliff period and the duration of this period;
    - what percentage of the remaining tokens will be distributed equally over equal time intervals (as well as the number and duration of these intervals).
    Any of these fields can accept zero values, for example, you can set the distribution of tokens without a cliff period or, conversely, split the receipt of values into two parts (immediately and after some time), without specifying time intervals.
    @dev For each TGE, a list of Resolvers can be assigned, i.e., addresses that can stop the vesting program for a specific user. 
    The list of resolvers is immutable for each individual TGE and is set at the time of its launch (it can be stored in the proposal data for creating the TGE beforehand).
    */
contract Vesting is Initializable, IVesting, ERC2771Context {
    using SafeERC20Upgradeable for IToken;

    // CONSTANTS

    /** 
    * @notice Denominator for shares (such as thresholds)
    * @dev The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account.
    */
    uint256 private constant DENOM = 100 * 10 ** 4;

    // STORAGE

    /// @notice Registry contract address
    IRegistry public registry;

    /// @notice Mapping that stores the total amount of tokens locked in vesting for each conducted TGE.
    /// @dev Claiming tokens does not modify these data; they are used to calculate the amount of tokens that can be claimed by a specific address and to determine the total amount of tokens in vesting for a given account.
    /// @dev In the event of vesting cancellation for a specific address in any TGE, the value under the TGE address key is decreased by the full amount of tokens locked in vesting for that address.
    mapping(address => uint256) public totalVested;

    /// @notice Mapping (tge, account) to amount of tokens vested to that account in TGE
    /// @dev The vesting contract does not store tokens, but it contains records of which address is entitled to what amount of tokens for which TGE when the conditions set in the settings are met. This means that minting these tokens only occurs when the owner of the address requests them, prior to that, they are not included in totalSupply or balances. No record in Vesting can affect the vote calculation for Governance.
    mapping(address => mapping(address => uint256)) public vested;

    /// @notice Mapping that stores the total amount of tokens vested by a specific address for a given TGE.
    /// @dev This parameter increases every time a successful transaction is made to the Claim method by an address.
    mapping(address => mapping(address => uint256)) public claimed;

    /// @notice Mapping of flags indicating whether the TVL threshold set in the TGE conditions has been reached by the pool.
    /// @dev It is one of the two conditions under which users can claim tokens reserved for them under the vesting program.
    mapping(address => bool) public claimTVLReached;

    /// @notice Mapping that shows the amount of tokens that will not be transferred to the user during claiming due to the cancellation of vesting by a resolver.
    mapping(address => mapping(address => uint256)) public resolved;

    // EVENTS

    /**
    * @dev This event is emitted when new token units are vested due to token purchase.
    * @param tge TGE contract address
    * @param account Account address
    * @param amount Amount of tokens vested for the account
    */
    event Vested(address tge, address account, uint256 amount);

    /**
    * @dev This event is emitted for each token claiming by users.
    * @param tge TGE contract address
    * @param account Account address that requested the token claiming
    * @param amount Amount of claimed tokens
    */
    event Claimed(address tge, address account, uint256 amount);

    /**
    * @dev This event is emitted when vesting is canceled for a specific account and TGE.
    * @param tge TGE contract address
    * @param account Account address
    * @param amount Amount of tokens that will not be distributed to this address due to the cancellation
    */
    event Cancelled(address tge, address account, uint256 amount);

    // MODIFIERS

    /// @notice Modifier allows the method to be called only by the TGE contract.
    /// @dev This modifier is commonly used for calling the `vest` method, which registers the arrival of new token units into vesting as a result of a successful `purchase` method call in the TGE contract.
    modifier onlyTGE() {
        require(
            registry.typeOf(_msgSender()) == IRecordsRegistry.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }
    
    /// @notice Modifier allows the method to be called only by an account that has the role of `SERVICE_MANAGER` in the Service contract.
    /// @dev It restricts access to certain privileged actions that are reserved for the manager.
    modifier onlyManager() {
        IService service = registry.service();
        require(
            service.hasRole(service.SERVICE_MANAGER_ROLE(), _msgSender()),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    /// @notice Modifier allows the method to be called only by an account whose address is specified in the list of resolvers for a given TGE.
    modifier onlyResolverOrTGE(address tge) {
        if (_msgSender() != tge) {
            address[] memory resolvers = ITGE(tge)
                .getInfo()
                .vestingParams
                .resolvers;
            bool isResolver;
            for (uint256 i = 0; i < resolvers.length; i++) {
                if (resolvers[i] == _msgSender()) {
                    isResolver = true;
                    break;
                }
            }
            require(isResolver, ExceptionsLibrary.NOT_RESOLVER);
        }
        _;
    }

    // INITIALIZER AND CONSTRUCTOR

    /**
     * @notice Contract constructor.
     * @dev This contract uses OpenZeppelin upgrades and has no need for a constructor function.
     * The constructor is replaced with an initializer function.
     * This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract initializer
     * @dev This method replaces the constructor for upgradeable contracts. Additionally, it sets the address of the Registry contract in the contract's storage.
     * @param registry_ Protocol registry address
     */
    function initialize(IRegistry registry_) external initializer {
        registry = registry_;
    }

    // PUBLIC FUNCTIONS

    /**
    * @notice Method for increasing the token balance in vesting for a specific TGE contract.
    * @dev This method is called only by the TGE contract and results in the creation of a new entry or an increase in the existing value in the vested mapping for the TGE key and the specified account. After this, the account is reserved the ability to mint and receive new token units in case the conditions specified in the vesting program for this TGE are met.
    * @param to Account address that received the vested tokens
    * @param amount Amount of tokens to vest
     */
    function vest(address to, uint256 amount) external onlyTGE {
        totalVested[_msgSender()] += amount;
        vested[_msgSender()][to] += amount;

        emit Vested(_msgSender(), to, amount);
    }

    /**
    * @notice Method for recording the occurrence of one of two conditions for token unlocking.
    * @dev This method can only be called by the address with the SERVICE_MANAGER role in the Service contract. It is a trusted way to load data into the source of truth about the TVL events achieved by the pool, as specified in the parameters of the vesting program.
    * @param tge TGE contract address
     */
    function setClaimTVLReached(address tge) external onlyManager {
        require(
            ITGE(tge).state() == ITGE.State.Successful,
            ExceptionsLibrary.WRONG_STATE
        );
        claimTVLReached[tge] = true;
    }

    /**
    * @notice Cancels vesting for the specified account and TGE contract addresses.
    * @dev Calling this method is only possible by the address specified in the resolvers list for the specific TGE, and it leads to resetting the token balance in vesting for the specified address, depriving it of the ability to make successful token claiming within the specified TGE.
    * @param tge TGE contract address
    * @param account Account address
     */
    function cancel(
        address tge,
        address account
    ) external onlyResolverOrTGE(tge) {
        uint256 amount = vestedBalanceOf(tge, account);

        vested[tge][account] -= amount;
        totalVested[tge] -= amount;

        resolved[tge][account] += amount;

        emit Cancelled(tge, account, amount);
    }

    /**
    * @notice Method to issue and transfer unlocked tokens to the transaction sender's address.
    * @dev This method is executed with the specified TGE, for which the currently unlocked token volume is calculated. Calling the method results in the issuance and transfer of the entire calculated token volume to the sender's address.
    * @param tge TGE contract address
     */
    function claim(address tge) external {
        uint256 amount = claimableBalanceOf(tge, _msgSender());
        require(amount > 0, ExceptionsLibrary.CLAIM_NOT_AVAILABLE);

        claimed[tge][_msgSender()] += amount;
        totalVested[tge] -= amount;

        address token = ITGE(tge).token();
        uint256 tokenId = ITGE(tge).tokenId();
        if (ITGE(tge).isERC1155TGE()) {
            ITokenERC1155(token).setTGEVestedTokens(
                ITokenERC1155(token).getTotalTGEVestedTokens(tokenId) - amount,
                tokenId
            );

            ITokenERC1155(token).mint(_msgSender(), tokenId, amount);
        } else {
            IToken(token).setTGEVestedTokens(
                IToken(token).getTotalTGEVestedTokens() - amount
            );

            IToken(token).mint(_msgSender(), amount);
        }

        IToken(token).service().registry().log(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(IVesting.claim.selector, tge)
        );

        emit Claimed(tge, _msgSender(), amount);
    }

    // PUBLIC VIEW FUNCTIONS

    /**
    * @notice This method returns the vesting parameters specified for a specific TGE.
    * @param tge TGE contract address
    * @return VestingParams Vesting settings
     */
    function vestingParams(
        address tge
    ) public view returns (VestingParams memory) {
        return ITGE(tge).getInfo().vestingParams;
    }

    /**
    * @notice This method validates the vesting program parameters proposed for use in the created TGE contract.
    * @param params Vesting program parameters
    * @return bool True if params are valid (reverts otherwise)
     */
    function validateParams(
        VestingParams memory params
    ) public pure returns (bool) {
        require(
            params.cliffShare + params.spans * params.spanShare <= DENOM,
            ExceptionsLibrary.SHARES_SUM_EXCEEDS_ONE
        );
        return true;
    }

    /**
    * @notice This method returns the number of token units that have been unlocked for a specific account within the vesting program of a particular TGE.
    * @dev The returned value is the total sum of all quantities after all token unlocks that have occurred for this account within this TGE. In other words, claimed tokens are also part of this response.
    * @param tge TGE contract address
    * @param account Account address
    * @return uint256 Number of unlocked token units
     */
    function unlockedBalanceOf(
        address tge,
        address account
    ) public view returns (uint256) {
        // In active or failed TGE nothing is unlocked
        if (ITGE(tge).state() != ITGE.State.Successful) {
            return 0;
        }

        // Is claim TVL is non-zero and is not reached, nothing is unlocked
        VestingParams memory params = vestingParams(tge);
        if (params.claimTVL > 0 && !claimTVLReached[tge]) {
            return 0;
        }

        // Determine unlocked amount
        uint256 tgeEnd = ITGE(tge).getEnd();
        if (block.number < tgeEnd + params.cliff) {
            // If cliff is not exceeded, nothing is unlocked yet
            return 0;
        } else if (
            block.number <
            tgeEnd + params.cliff + params.spans * params.spanDuration
        ) {
            // If cliff is reached, but not all the period passed, calculate vested amount
            uint256 spansUnlocked = (block.number - tgeEnd - params.cliff) /
                params.spanDuration;
            uint256 totalShare = params.cliffShare +
                spansUnlocked *
                params.spanShare;
            return (vested[tge][account] * totalShare) / DENOM;
        } else {
            // Otherwise everything is unlocked
            return vested[tge][account];
        }
    }

    /**
    * @notice This method returns the currently available amount of token units that an account can claim within the specified TGE.
    * @dev This method takes into account previous claimings made by the account.
    * @param tge TGE contract address
    * @param account Account address
    * @return uin256 Number of claimable token units
     */
    function claimableBalanceOf(
        address tge,
        address account
    ) public view returns (uint256) {
        return unlockedBalanceOf(tge, account) - claimed[tge][account];
    }

    /**
    * @notice This method shows the remaining tokens that are still vested for a given address.
    * @dev This method shows both still locked token units and already unlocked units ready for claiming.
    * @param tge TGE contract address
    * @param account Account address
    * @return uint256 Number of token units vested
     */
    function vestedBalanceOf(
        address tge,
        address account
    ) public view returns (uint256) {
        return vested[tge][account] - claimed[tge][account];
    }

    function getTrustedForwarder() public view override returns (address) {
        return registry.service().getTrustedForwarder();
    }
     function _msgSender() internal view override returns (address sender) {
       return super._msgSender();
    }

    function _msgData() internal view override returns (bytes calldata) {
        return super._msgData();
    }
}
