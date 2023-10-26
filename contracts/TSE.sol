// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITokenERC1155.sol";
import "./interfaces/ITSE.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IVesting.sol";
import "./libraries/ExceptionsLibrary.sol";
import "./interfaces/IPausable.sol";
import "./utils/CustomContext.sol";

/**
    * @title Token Generation Event Contract
    * @notice The Token Generation Event (TSE) is the cornerstone of everything related to tokens issued on the CompanyDAO protocol. TSE contracts contain the rules and deadlines for token distribution events and can influence the pool's operational activities even after they have ended.
    The launch of the TSE event takes place simultaneously with the deployment of the contract, after which the option to purchase tokens becomes immediately available. Tokens purchased by a user can be partially or fully minted to the buyer's address and can also be placed in the vesting reserve either in full or for the remaining portion. Additionally, tokens acquired during the TSE and held in the buyer's balance may have their transfer functionality locked (the user owns, uses them as votes, delegates, but cannot transfer the tokens to another address).
    * @dev TSE events differ by the type of tokens being distributed:
    - Governance Token Generation Event
    - Preference Token Generation Event
    When deploying the TSE contract, among other arguments, the callData field contains the token field, which contains the address of the token contract that will interact with the TSE contract. The token type can be determined from the TokenType state variable of the token contract.
    Differences between these types:
    - Governance Token Generation Event involves charging a ProtocolTokenFee in the amount set in the Service:protocolTokenFee value (percentages in DENOM notation). This fee is collected through the transferFunds() transaction after the completion of the Governance token distribution event (the funds collected from buyers go to the pool balance, and the protocolTokenFee is minted and sent to the Service:protocolTreasury).
    - Governance Token Generation Event has a mandatory minPurchase limit equal to the Service:protocolTokenFee (in the smallest indivisible token parts, taking into account Decimals and DENOM). This is done to avoid rounding conflicts or overcharges when calculating the fee for each issued token volume.
    - In addition to being launched as a result of a proposal execution, a Governance Token Generation Event can be launched by the pool Owner as long as the pool has not acquired DAO status. Preference Token Generation Event can only be launched as a result of a proposal execution.
    - A successful Governance Token Generation Event (see TSE states later) leads to the pool becoming a DAO if it didn't previously have that status.
    @dev **TSE events differ by the number of previous launches:**
    - primary TSE
    - secondary TSE
    As long as the sum of the totalSupply and the vesting reserve of the distributed token does not equal the cap, a TSE can be launched to issue some more of these tokens.
    The first TSE for the distribution of any token is called primary, and all subsequent ones are called secondary.
    Differences between these types:
    - A transaction to launch a primary TSE involves the simultaneous deployment of the token contract, while a secondary TSE only works with an existing token contract.
    - A secondary TSE does not have a softcap parameter, meaning that after at least one minPurchase of tokens, the TSE is considered successful.
    - When validating the hardcap (i.e., the maximum possible number of tokens available for sale/distribution within the TSE) during the creation of a primary TSE, only a formal check is performed (hardcap must not be less than softcap and not greater than cap). For a secondary TSE, tokens that will be minted during vesting claims are also taken into account.
    - In case of failure of a primary TSE for any token, that token is not considered to have any application within the protocol. It is no longer possible to conduct a TSE for such a token.
    */

contract TSE is
    Initializable,
    ReentrancyGuardUpgradeable,
    ITSE,
    ERC2771Context
{
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

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

    address public seller;

    /// @notice The address of the ERC20/ERC1155 token being distributed in this TSE
    /// @dev Mandatory setting for TSE, only one token can be distributed in a single TSE event
    address public token;

    /// @notice The identifier of the ERC1155 token collection
    /// @dev For ERC1155, there is an additional restriction that units of only one collection of such tokens can be distributed in a single TSE
    uint256 public tokenId;

    /// @dev Parameters for conducting the TSE, described by the ITSE.sol:TSEInfo interface
    TSEInfo public info;

    /**
    * @notice A whitelist of addresses allowed to participate in this TSE
    * @dev A TSE can be public or private. To make the event public, simply leave the whitelist empty.
    The TSE contract can act as an airdrop - a free token distribution. To do this, set the price value to zero.
    To create a DAO with a finite number of participants, each of whom should receive an equal share of tokens, you can set the whitelist when launching the TSE as a list of the participants' addresses, and set both minPurchase and maxPurchase equal to the expression (hardcap / number of participants). To make the pool obtain DAO status only if the distribution is successful under such conditions for all project participants, you can set the softcap value equal to the hardcap. With these settings, the company will become a DAO only if all the initial participants have an equal voting power.
    */
    mapping(address => bool) private _isUserWhitelisted;

    /// @dev The block on which the TSE contract was deployed and the event begins
    uint256 public createdAt;

    /// @dev A mapping that stores the amount of token units purchased by each address that plays a key role in the TSE.
    mapping(address => uint256) public purchaseOf;

    /// @dev Total amount of tokens purchased during the TSE
    uint256 public totalPurchased;

    event Purchased(address buyer, uint256 amount);

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
     * @dev Constructor function, can only be called once. In this method, settings for the TSE event are assigned, such as the contract of the token implemented using TSE, as well as the TSEInfo structure, which includes the parameters of purchase, vesting, and lockup. If no lockup or vesting conditions were set for the TVL value when creating the TSE, then the TVL achievement flag is set to true from the very beginning.
     * @param _service Service contract
     * @param _token TSE's token
     * @param _tokenId TSE's tokenId
     * @param _tokenId ERC1155TSE's tokenId (token series)
     * @param _info TSE parameters
     */
    function initialize(
        address _service,
        address _token,
        uint256 _tokenId,
        TSEInfo calldata _info,
        address _seller
    ) external initializer {
        __ReentrancyGuard_init();

        //if tse is creating for erc20 token
        tokenId = _tokenId;

        token = _token;

        info = _info;

        seller  = _seller;

        for (uint256 i = 0; i < _info.userWhitelist.length; i++) {
            _isUserWhitelisted[_info.userWhitelist[i]] = true;
        }

        createdAt = block.number;
    }

    // PUBLIC FUNCTIONS
    receive() external payable {}

    /**
    * @notice This method is used for purchasing pool tokens.
    * @dev Any blockchain address can act as a buyer (TSE contract user) of tokens if the following conditions are met:
    - active event status (TSE.sol:state method returns the Active code value / "1")
    - the event is public (TSE.sol:info.Whitelist is empty) or the user's address is on the whitelist of addresses admitted to the event
    - the number of tokens purchased by the address is not less than TSE.sol:minPurchase (a common rule for all participants) and not more than TSE.sol:maxPurchaseOf(address) (calculated individually for each address)
    The TSEInfo of each such event also contains settings for the order in which token buyers receive their purchases and from when and to what extent they can start managing them.
    However, in any case, each address that made a purchase is mentioned in the TSE.sol:purchaseOf[] mapping. This record serves as proof of full payment for the purchase and confirmation of the buyer's status, even if as a result of the transaction, not a single token was credited to the buyer's address.
    After each purchase transaction, TSE.sol:purchase calculates what part of the purchase should be issued and immediately transferred to the buyer's balance, and what part should be left as a reserve (records, not issued tokens) in vesting until the prescribed settings for unlocking these tokens occur.
     */
    function purchase(
        uint256 amount
    )
        external
        payable
        onlyWhitelistedUser
        onlyState(State.Active)
        nonReentrant
        whenPoolNotPaused
    {
        // Check purchase price transfer depending on unit of account
        address unitOfAccount = info.unitOfAccount;
        uint256 purchasePrice = (amount * info.price + (1 ether - 1)) / 1 ether;
        if (unitOfAccount == address(0)) {
            require(
                msg.value >= purchasePrice,
                ExceptionsLibrary.INCORRECT_ETH_PASSED
            );
            (bool sent, bytes memory data) = payable(seller).call{value: msg.value}("");
            require(sent, "Failed to send");
        } else {
            IERC20Upgradeable(unitOfAccount).safeTransferFrom(
                _msgSender(),
                seller,
                purchasePrice
            );
        }
        this.proceedPurchase(_msgSender(), amount);
    }

    /**
     * @notice Executes a token purchase for a given account using fiat during the token generation event (TSE).
     * @dev The function can only be called by an executor, when the contract state is active, the pool is not paused, and ensures no reentrancy.
     * @param account The address of the account to execute the purchase for.
     * @param amount The amount of tokens to be purchased.
     */

    function externalPurchase(
        address account,
        uint256 amount
    )
        external
        onlyManager
        onlyState(State.Active)
        nonReentrant
        whenPoolNotPaused
    {
        try this.proceedPurchase(account, amount) {
            return;
        } catch {
            _refund(account, amount);
            return;
        }
    }

    function finishTSE()
        external
        whenPoolNotPaused
    {
        require(
            _msgSender()==seller,
            ExceptionsLibrary.INVALID_USER
        );
        info.amount = totalPurchased;
        
        if (isERC1155TSE()) {
            ITokenERC1155(token).transfer(address(this), seller, tokenId, ITokenERC1155(token).balanceOf(address(this), tokenId));
        } else {
            IToken(token).transfer( seller, IToken(token).balanceOf(address(this)));
        }

        IToken(token).service().registry().log(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(ITSE.finishTSE.selector)
        );
    }

    // RESTRICTED FUNCTIONS

    function _refund(address account, uint256 amount) private {
        uint256 refundValue = (amount * info.price + (1 ether - 1)) / 1 ether;
        if (info.unitOfAccount == address(0)) {
            payable(_msgSender()).sendValue(refundValue);
        } else {
            IERC20Upgradeable(info.unitOfAccount).safeTransfer(
                _msgSender(),
                refundValue
            );
        }
    }

    // VIEW FUNCTIONS

    /**
     * @dev Shows the maximum possible number of tokens to be purchased by a specific address, taking into account whether the user is on the white list and 0 what amount of purchases he made within this TSE.
     * @return Amount of tokens
     */
    function maxPurchaseOf(address account) public view returns (uint256) {
        if (!isUserWhitelisted(account)) {
            return 0;
        }
        return
            MathUpgradeable.min(
                info.maxPurchase - purchaseOf[account],
                info.amount - totalPurchased
            );
    }

    /**
    * @notice A state of a Token Generation Event
    * @dev A TSE event can be in one of the following states:
    - Active
    - Failed
    - Successful
    In TSEInfo, the three most important parameters used to determine the event's state are specified:
    - hardcap - the maximum number of tokens that can be distributed during the event (the value is stored considering the token's Decimals)
    - softcap - the minimum expected number of tokens that should be distributed during the event (the value is stored considering the token's Decimals)
    - duration - the duration of the event (the number of blocks since the TSE deployment transaction)
    A successful outcome of the event and the assignment of the "Successful" status to the TSE occurs if:
    - no fewer than duration blocks have passed since the TSE launch, and no fewer than softcap tokens have been acquired
    OR
    - 100% of the hardcap tokens have been acquired at any point during the event
    If no fewer than duration blocks have passed since the TSE launch and fewer than softcap tokens have been acquired, the event is considered "Failed".
    If fewer than 100% of the hardcap tokens have been acquired, but fewer than duration blocks have passed since the TSE launch, the event is considered "Active".
     * @return State code
     */
    function state() public view returns (State) {
        // If hardcap is reached TSE is successfull
        if (totalPurchased == info.amount) {
            return State.Successful;
        }

        // If deadline not reached TSE is active
        if (block.number < createdAt + info.duration) {
            return State.Active;
        }

        // If totalPurchased > 0  TSE is successfull
        if (block.number > createdAt + info.duration && totalPurchased > 0) {
            return State.Successful;
        }

        // Otherwise it's failed primary TSE
        return State.Failed;
    }

    /**
     * @dev The given getter shows how much info.unitofaccount was collected within this TSE. To do this, the amount of tokens purchased by all buyers is multiplied by info.price.
     * @return uint256 Total value
     */
    function getTotalPurchasedValue() public view returns (uint256) {
        return (totalPurchased * info.price) / 10 ** 18;
    }

    /**
     * @dev This method returns the full list of addresses allowed to participate in the TSE.
     * @return address An array of whitelist addresses
     */
    function getUserWhitelist() external view returns (address[] memory) {
        return info.userWhitelist;
    }

    /**
     * @dev Checks if user is whitelisted.
     * @param account User address
     * @return 'True' if the whitelist is empty (public TSE) or if the address is found in the whitelist, 'False' otherwise.
     */
    function isUserWhitelisted(address account) public view returns (bool) {
        return info.userWhitelist.length == 0 || _isUserWhitelisted[account];
    }

    /**
     * @dev This method indicates whether this event was launched to implement ERC1155 tokens.
     * @return bool Flag if ERC1155 TSE
     */
    function isERC1155TSE() public view returns (bool) {
        return tokenId == 0 ? false : true;
    }

    /**
     * @dev Returns the block number at which the event ends.
     * @return uint256 Block number
     */
    function getEnd() external view returns (uint256) {
        return createdAt + info.duration;
    }

    /**
    * @notice This method returns the immutable settings with which the TSE was launched.
    * @dev The rules for conducting an event are defined in the TSEInfo structure, which is passed within the calldata when calling one of the TSEFactory contract functions responsible for launching the TSE. For more information about the structure, see the "Interfaces" section. The variables mentioned below should be understood as attributes of the TSEInfo structure.
    A TSE can be public or private. To make the event public, simply leave the whitelist empty.
    The TSE contract can act as an airdrop - a free token distribution. To do this, set the price value to zero.
    To create a DAO with a finite number of participants, each of whom should receive an equal share of tokens, you can set the whitelist when launching the TSE as a list of the participants' addresses, and set both minPurchase and maxPurchase equal to the expression (hardcap / number of participants). To make the pool obtain DAO status only if the distribution is successful under such conditions for all project participants, you can set the softcap value equal to the hardcap. With these settings, the company will become a DAO only if all the initial participants have an equal voting power.
    * @return The settings in the form of a TSEInfo structure
    */
    function getInfo() external view returns (TSEInfo memory) {
        return info;
    }

    /// @notice Determine if a purchase is valid for a specific account and amount.
    /// @dev Returns true if the amount is within the permitted purchase range for the account.
    /// @param account The address of the account to validate the purchase for.
    /// @param amount The amount of the purchase to validate.
    /// @return A boolean value indicating if the purchase is valid.
    function validatePurchase(
        address account,
        uint256 amount
    ) public view returns (bool) {
        return
            amount > 0 &&
            amount >= info.minPurchase &&
            amount <= maxPurchaseOf(account);
    }

    //PRIVATE FUNCTIONS

    function proceedPurchase(address account, uint256 amount) public {
        require(_msgSender() == address(this), ExceptionsLibrary.INVALID_USER);

        require(
            validatePurchase(account, amount),
            ExceptionsLibrary.INVALID_PURCHASE_AMOUNT
        );

        // Accrue TSE stats
        totalPurchased += amount;
        purchaseOf[account] += amount;

        if (isERC1155TSE()) {

            ITokenERC1155(token).transfer(address(this), account, tokenId, amount);
        } else {
            IToken(token).transfer( account, amount);
        }

        // Emit event
        emit Purchased(account, amount);

        IToken(token).service().registry().log(
            account,
            address(this),
            0,
            abi.encodeWithSelector(ITSE.purchase.selector, amount)
        );
    }

    // MODIFIER

    /// @notice Modifier that allows the method to be called only if the TSE state is equal to the specified state.
    modifier onlyState(State state_) {
        require(state() == state_, ExceptionsLibrary.WRONG_STATE);
        _;
    }

    /// @notice Modifier that allows the method to be called only by an account that is whitelisted for the TSE or if the TSE is created as public.
    modifier onlyWhitelistedUser() {
        require(
            isUserWhitelisted(_msgSender()),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by an account that has the ADMIN role in the Service contract.
    modifier onlyManager() {
        IService service = IToken(token).service();
        require(
            service.hasRole(service.SERVICE_MANAGER_ROLE(), _msgSender()),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only if the pool associated with the event is not in a paused state.
    modifier whenPoolNotPaused() {
        require(
            !IPausable(IToken(token).pool()).paused(),
            ExceptionsLibrary.SERVICE_PAUSED
        );
        _;
    }

    modifier onlyCompanyManager() {
        IRegistry registry = IToken(token).service().registry();
        require(
            registry.hasRole(registry.COMPANIES_MANAGER_ROLE(), _msgSender()),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    function getTrustedForwarder() public view override returns (address) {
        return IToken(token).service().getTrustedForwarder();
    }

    function _msgSender() internal view override returns (address sender) {
        return super._msgSender();
    }

    function _msgData() internal view override returns (bytes calldata) {
        return super._msgData();
    }
}
