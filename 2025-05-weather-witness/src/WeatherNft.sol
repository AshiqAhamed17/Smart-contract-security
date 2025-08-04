// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import {WeatherNftStore} from "./WeatherNftStore.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {IAutomationRegistryMaster} from "@chainlink/contracts/src/v0.8/automation/interfaces/v2_2/IAutomationRegistryMaster.sol";
import {IAutomationRegistrarInterface} from "./interfaces/IAutomationRegistrarInterface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract WeatherNft is
    WeatherNftStore,
    ERC721,
    FunctionsClient,
    ConfirmedOwner,
    AutomationCompatibleInterface
{
    using FunctionsRequest for FunctionsRequest.Request;
    using SafeERC20 for IERC20;

    // constructor
    constructor(
        Weather[] memory weathers,
        string[] memory weatherURIs,
        address functionsRouter,
        FunctionsConfig memory _config,
        uint256 _currentMintPrice,
        uint256 _stepIncreasePerMint,
        address _link,
        address _keeperRegistry,
        address _keeperRegistrar,
        uint32 _upkeepGaslimit
    )
        ERC721("Weather NFT", "W-NFT")
        FunctionsClient(functionsRouter)
        ConfirmedOwner(msg.sender)
    {
        require(
            weathers.length == weatherURIs.length,
            WeatherNft__IncorrectLength()
        );

        for (uint256 i; i < weathers.length; ++i) {
            s_weatherToTokenURI[weathers[i]] = weatherURIs[i];
        }

        s_functionsConfig = _config;
        s_currentMintPrice = _currentMintPrice;
        s_stepIncreasePerMint = _stepIncreasePerMint;
        s_link = _link;
        s_keeperRegistry = _keeperRegistry;
        s_keeperRegistrar = _keeperRegistrar;
        s_upkeepGaslimit = _upkeepGaslimit;
        s_tokenCounter = 1;
    }

    // functions
    function updateFunctionsGasLimit(uint32 newGaslimit) external onlyOwner {
        s_functionsConfig.gasLimit = newGaslimit;
    }

    function updateSubId(uint64 newSubId) external onlyOwner {
        s_functionsConfig.subId = newSubId;
    }

    function updateSource(string memory newSource) external onlyOwner {
        s_functionsConfig.source = newSource;
    }

    function updateEncryptedSecretsURL(
        bytes memory newEncryptedSecretsURL
    ) external onlyOwner {
        s_functionsConfig.encryptedSecretsURL = newEncryptedSecretsURL;
    }

    function updateKeeperGaslimit(uint32 newGaslimit) external onlyOwner {
        s_upkeepGaslimit = newGaslimit;
    }

    function _sendFunctionsWeatherFetchRequest(
        string memory _pincode,
        string memory _isoCode
    ) internal returns (bytes32 _reqId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_functionsConfig.source);
        string[] memory _args = new string[](2);
        _args[0] = _pincode;
        _args[1] = _isoCode;

        req.setArgs(_args);

        _reqId = _sendRequest(
            req.encodeCBOR(),
            s_functionsConfig.subId,
            s_functionsConfig.gasLimit,
            s_functionsConfig.donId
        );
    }

    function requestMintWeatherNFT(
        string memory _pincode,
        string memory _isoCode,
        bool _registerKeeper,
        uint256 _heartbeat,
        uint256 _initLinkDeposit
    ) external payable returns (bytes32 _reqId) {
        require(
            msg.value == s_currentMintPrice,
            WeatherNft__InvalidAmountSent()
        );
        s_currentMintPrice += s_stepIncreasePerMint;

        if (_registerKeeper) {
            IERC20(s_link).safeTransferFrom(
                msg.sender,
                address(this),
                _initLinkDeposit
            );
        }

        _reqId = _sendFunctionsWeatherFetchRequest(_pincode, _isoCode);

        emit WeatherNFTMintRequestSent(msg.sender, _pincode, _isoCode, _reqId);

        s_funcReqIdToUserMintReq[_reqId] = UserMintRequest({
            user: msg.sender,
            pincode: _pincode,
            isoCode: _isoCode,
            registerKeeper: _registerKeeper,
            heartbeat: _heartbeat,
            initLinkDeposit: _initLinkDeposit
        });
    }

    function fulfillMintRequest(bytes32 requestId) external {
        bytes memory response = s_funcReqIdToMintFunctionReqResponse[requestId]
            .response;
        bytes memory err = s_funcReqIdToMintFunctionReqResponse[requestId].err;

        require(
            response.length > 0 || err.length > 0,
            WeatherNft__Unauthorized()
        );

        if (response.length == 0 || err.length > 0) {
            return;
        }

        UserMintRequest memory _userMintRequest = s_funcReqIdToUserMintReq[
            requestId
        ];
        uint8 weather = abi.decode(response, (uint8));
        uint256 tokenId = s_tokenCounter;
        s_tokenCounter++;

        emit WeatherNFTMinted(requestId, msg.sender, Weather(weather));
        _mint(msg.sender, tokenId);
        s_tokenIdToWeather[tokenId] = Weather(weather);

        uint256 upkeepId;
        if (_userMintRequest.registerKeeper) {
            // Register chainlink keeper to pull weather data in order to automate weather nft
            LinkTokenInterface(s_link).approve(
                s_keeperRegistrar,
                _userMintRequest.initLinkDeposit
            );

            IAutomationRegistrarInterface.RegistrationParams
                memory _keeperParams = IAutomationRegistrarInterface
                    .RegistrationParams({
                        name: string.concat(
                            "Weather NFT Keeper: ",
                            Strings.toString(tokenId)
                        ),
                        encryptedEmail: "",
                        upkeepContract: address(this),
                        gasLimit: s_upkeepGaslimit,
                        adminAddress: address(this),
                        triggerType: 0,
                        checkData: abi.encode(tokenId),
                        triggerConfig: "",
                        offchainConfig: "",
                        amount: uint96(_userMintRequest.initLinkDeposit)
                    });

            upkeepId = IAutomationRegistrarInterface(s_keeperRegistrar)
                .registerUpkeep(_keeperParams);
        }

        s_weatherNftInfo[tokenId] = WeatherNftInfo({
            heartbeat: _userMintRequest.heartbeat,
            lastFulfilledAt: block.timestamp,
            upkeepId: upkeepId,
            pincode: _userMintRequest.pincode,
            isoCode: _userMintRequest.isoCode
        });
    }

    function _fulfillWeatherUpdate(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal {
        if (response.length == 0 || err.length > 0) {
            return;
        }

        uint256 tokenId = s_funcReqIdToTokenIdUpdate[requestId];
        uint8 weather = abi.decode(response, (uint8));
        s_weatherNftInfo[tokenId].lastFulfilledAt = block.timestamp;
        s_tokenIdToWeather[tokenId] = Weather(weather);

        emit NftWeatherUpdated(tokenId, Weather(weather));
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_funcReqIdToUserMintReq[requestId].user != address(0)) {
            s_funcReqIdToMintFunctionReqResponse[
                requestId
            ] = MintFunctionReqResponse({response: response, err: err});
        } else if (s_funcReqIdToTokenIdUpdate[requestId] > 0) {
            _fulfillWeatherUpdate(requestId, response, err);
        }
    }

    function checkUpkeep(
        bytes calldata checkData
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 _tokenId = abi.decode(checkData, (uint256));
        if (_ownerOf(_tokenId) == address(0)) {
            upkeepNeeded = false;
        } else {
            upkeepNeeded = (block.timestamp >=
                s_weatherNftInfo[_tokenId].lastFulfilledAt +
                    s_weatherNftInfo[_tokenId].heartbeat);
            if (upkeepNeeded) {
                performData = checkData;
            }
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 _tokenId = abi.decode(performData, (uint256));
        uint256 upkeepId = s_weatherNftInfo[_tokenId].upkeepId;

        s_weatherNftInfo[_tokenId].lastFulfilledAt = block.timestamp;

        // make functions request
        string memory pincode = s_weatherNftInfo[_tokenId].pincode;
        string memory isoCode = s_weatherNftInfo[_tokenId].isoCode;

        bytes32 _reqId = _sendFunctionsWeatherFetchRequest(pincode, isoCode);
        s_funcReqIdToTokenIdUpdate[_reqId] = _tokenId;

        emit NftWeatherUpdateRequestSend(_tokenId, _reqId, upkeepId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory image = s_weatherToTokenURI[s_tokenIdToWeather[tokenId]]; //@audit what if the image is corrupted and doesn't return.

        //@audit - med  use abi.encode() instead of abi.encodePacked() to prevent hash collisions
        bytes memory jsonData = abi.encodePacked(
            '{"name": "Weathear NFT", "user": "',
            Strings.toHexString(_ownerOf(tokenId)),
            '", "image": "',
            image,
            '"}'
        );

        string memory base64TransformedData = Base64.encode(jsonData);

        return string.concat(_baseURI(), base64TransformedData);
    }
}
