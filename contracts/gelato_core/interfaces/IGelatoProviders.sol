pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import { IGelatoProviderModule } from "./IGelatoProviderModule.sol";
import { Action, ExecClaim } from "../interfaces/IGelatoCore.sol";
import { IGelatoCondition } from "../../gelato_conditions/IGelatoCondition.sol";

interface IGelatoProviders {

    // IceCream - Will be whitelised by providers and selected by users
    struct IceCream {
        IGelatoCondition condition;   // Address: optional AddressZero for self-conditional actions
        Action[] actions;
        uint256 gasPriceCeil;  // GasPriceCeil
    }

    // Provider Funding
    event LogProvideFunds(
        address indexed provider,
        uint256 amount,
        uint256 newProviderFunds
    );
    event LogUnprovideFunds(
        address indexed provider,
        uint256 realWithdrawAmount,
        uint256 newProviderFunds
    );

    // Executor By Provider
    event LogProviderAssignsExecutor(
        address indexed provider,
        address indexed oldExecutor,
        address indexed newExecutor
    );
    event LogExecutorAssignsExecutor(
        address indexed provider,
        address indexed oldExecutor,
        address indexed newExecutor
    );

    // Actions
    event LogProvideIceCream(address indexed provider, bytes32 indexed iceCreamHash);
    event LogUnprovideIceCream(address indexed provider, bytes32 indexed iceCreamHash);
    event LogSetIceCreamGasPriceCeil(
        address indexed provider,
        bytes32 iceCreamHash,
        uint256 oldIceCreamGasPriceCeil,
        uint256 newIceCreamGasPriceCeil
    );

    // Provider Module
    event LogAddProviderModule(
        address indexed provider,
        IGelatoProviderModule indexed module
    );
    event LogRemoveProviderModule(
        address indexed provider,
        IGelatoProviderModule indexed module
    );

    // =========== GELATO PROVIDER APIs ==============

    /// @notice Validation that checks whether inputetd Ice Cream is being offered by the selected provider
    /// @dev Checked in createExecClaim() if provider != userProxy
    /// @param _provider Address of selected provider
    /// @param _condition Address of condition which will be checked
    /// @param _actions Acion Struct defined in IGelatoCore
    /// @return Expected to return "OK"
    function isIceCreamProvided(
        address _provider,
        IGelatoCondition _condition,
        Action[] calldata _actions
    )
        external
        view
        returns(string memory);

    /// @notice Validates that provider has provider module whitelisted + conducts isProvided check in ProviderModule
    /// @dev Checked in createExecClaim() if provider == userProxy
    /// @param _ec Execution Claim defined in IGelatoCore
    /// @return Expected to return "OK"
    function providerModuleChecks(ExecClaim calldata _ec)
        external
        view
        returns(string memory);


    /// @notice Validate if provider module and seleced IceCream is whitelisted by provider
    /// @dev Combines "isIceCreamProvided" and providerModuleChecks
    /// @param _ec Execution Claim defined in IGelatoCore
    /// @return res Expected to return "OK"
    function isExecClaimProvided(ExecClaim calldata _ec)
        external
        view
        returns(string memory res);


    /// @notice Validate if selected IceCream is whitelisted by provider and that current gelatoGasPrice is below GasPriceCeil
    /// @dev If gasPriceCeil is != 0, Ice Cream is whitelisted
    /// @param _ec Execution Claim defined in IGelatoCore
    /// @param _gelatoGasPrice Execution Claim defined in IGelatoCore
    /// @return res Expected to return "OK"
    function providerCanExec(ExecClaim calldata _ec, uint256 _gelatoGasPrice)
        external
        view
        returns(string memory res);

    // =========== PROVIDER STATE WRITE APIs ==============
    // Provider Funding
    /// @notice Deposit ETH as provider on Gelato
    /// @param _provider Address of provider who receives ETH deposit
    function provideFunds(address _provider) external payable;

    /// @notice Withdraw provider funds from gelato
    /// @param _withdrawAmount Amount
    /// @return amount that will be withdrawn
    function unprovideFunds(uint256 _withdrawAmount) external returns(uint256);

    /// @notice Assign executor as provider
    /// @param _executor Address of new executor
    function providerAssignsExecutor(address _executor) external;

    /// @notice Assign executor as previous selected executor
    /// @param _provider Address of provider whose executor to change
    /// @param _newExecutor Address of new executor
    function executorAssignsExecutor(address _provider, address _newExecutor) external;

    // (Un-)provide Ice Cream

    /// @notice Whitelist IceCreams (A combination of a Condition, Action(s) and a gasPriceCeil) that users can select from
    /// @dev If gasPriceCeil is == 0, Ice Cream will be executed at any gas price (no ceil)
    /// @param _IceCreams Execution Claim List defined in IGelatoCore
    function provideIceCreams(IceCream[] calldata _IceCreams) external;

    /// @notice De-whitelist IceCreams (A combination of a Condition, Action(s) and a gasPriceCeil) that users can select from
    /// @dev If gasPriceCeil was set to NO_CEIL, Input NO_CEIL constant as GasPriceCeil
    /// @param _IceCreams Execution Claim List defined in IGelatoCore
    function unprovideIceCreams(IceCream[] calldata _IceCreams) external;

    /// @notice Update gasPriceCeil of selected Ice Cream
    /// @param _iceCreamHash Result of iceCreamHash()
    /// @param _gasPriceCeil New gas price ceil for Ice Cream
    function setIceCreamGasPriceCeil(bytes32 _iceCreamHash, uint256 _gasPriceCeil) external;

    // Provider Module
    /// @notice Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be called during providerModuleChecks()
    function addProviderModules(IGelatoProviderModule[] calldata _modules) external;

    /// @notice De-Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be removed
    function removeProviderModules(IGelatoProviderModule[] calldata _modules) external;

    // Batch (un-)provide

    /// @notice Whitelist new executor, IceCream(s) and Module(s) in one tx
    /// @param _executor Address of new executor of provider
    /// @param _IceCreams List of Ice Cream which will be whitelisted by provider
    /// @param _modules List of module addresses which will be whitelisted by provider
    function batchProvide(
        address _executor,
        IceCream[] calldata _IceCreams,
        IGelatoProviderModule[] calldata _modules
    )
        external
        payable;


    /// @notice De-Whitelist IceCream(s), Module(s) and withdraw funds from gelato in one tx
    /// @param _withdrawAmount Amount to withdraw from ProviderFunds
    /// @param _IceCreams List of Ice Cream which will be de-whitelisted by provider
    /// @param _modules List of module addresses which will be de-whitelisted by provider
    function batchUnprovide(
        uint256 _withdrawAmount,
        IceCream[] calldata _IceCreams,
        IGelatoProviderModule[] calldata _modules
    )
        external;

    // =========== PROVIDER STATE READ APIs ==============
    // Provider Funding

    /// @notice Get balance of provider
    /// @param _provider Address of provider
    /// @return Provider Balance
    function providerFunds(address _provider) external view returns(uint256);

    /// @notice Get min stake required by all providers for executors to call exec
    /// @param _gelatoMaxGas Current gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return How much provider balance is required for executor to submit exec tx
    function minExecProviderFunds(uint256 _gelatoMaxGas, uint256 _gelatoGasPrice)
        external
        view
        returns(uint256);

    /// @notice Check if provider has sufficient funds for executor to call exec
    /// @param _provider Address of provider
    /// @param _gelatoMaxGas Currentt gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return Whether provider is liquid (true) or not (false)
    function isProviderLiquid(
        address _provider,
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    )
        external
        view
        returns(bool);

    // Executor Stake

    /// @notice Get balance of executor
    /// @param _executor Address of executor
    /// @return Executor Balance
    function executorStake(address _executor) external view returns(uint256);

    /// @notice Check if executor has sufficient stake on gelato
    /// @param _executor Address of provider
    /// @return Whether executor has sufficient stake (true) or not (false)
    function isExecutorMinStaked(address _executor) external view returns(bool);

    /// @notice Get executor of provider
    /// @param _provider Address of provider
    /// @return Provider's executor
    function executorByProvider(address _provider)
        external
        view
        returns(address);

    /// @notice Get num. of providers which haved assigned an executor
    /// @param _executor Address of executor
    /// @return Count of how many providers assigned the executor
    function executorProvidersCount(address _executor) external view returns(uint256);

    /// @notice Check if executor has one or more providers assigned
    /// @param _executor Address of provider
    /// @return Where 1 or more providers have assigned the executor
    function isExecutorAssigned(address _executor) external view returns(bool);

    // Ice Cream and Gas Price Ceil
    /// @notice The maximum gas price the transaction will be executed with
    /// @param _provider Address of provider
    /// @param _iceCreamHash Hash of provider IceCream
    /// @return Max gas price an executor will execute the transaction with in wei
    function iceCreamGasPriceCeil(address _provider, bytes32 _iceCreamHash)
        external
        view
        returns(uint256);

    /// @notice Compute an IceCreamHash
    /// @dev action.data can be 0
    /// @param _condition Address of condition instance
    /// @param _noDataActions Action List
    /// @return keccak256 hash of encoded condition address and Action List
    function iceCreamHash(IGelatoCondition _condition, Action[] calldata _noDataActions)
        external
        view
        returns(bytes32);

    /// @notice Constant used to specify the highest gas price available in the gelato system
    /// @dev Input 0 as gasPriceCeil and it will be assigned to NO_CEIL
    /// @return MAX_UINT
    function NO_CEIL() external pure returns(uint256);

    // Providers' Module Getters

    /// @notice Check if inputted module is whitelisted by provider
    /// @param _provider Address of provider
    /// @param _module Address of module
    /// @return true if it is whitelisted
    function isModuleProvided(address _provider, IGelatoProviderModule _module)
        external
        view
        returns(bool);

    /// @notice Get all whitelisted provider modules from a given provider
    /// @param _provider Address of provider
    /// @return List of whitelisted provider modules
    function providerModules(address _provider)
        external
        view
        returns(IGelatoProviderModule[] memory);
}
