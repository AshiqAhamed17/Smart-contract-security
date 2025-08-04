// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

contract WeatherNftStore {
    // errors
    error WeatherNft__IncorrectLength();
    error WeatherNft__InvalidAmountSent();
    error WeatherNft__Unauthorized();

    // enums
    //@audit Mismatch enum from the GetWeather.js
    enum Weather { 
        SUNNY, //0
        CLOUDY, //1
        RAINY, //2
        THUNDERSTORM, //3
        WINDY, //4
        SNOW //5
    }

    // structs
    struct FunctionsConfig {
        string source;
        bytes encryptedSecretsURL;
        uint64 subId;
        uint32 gasLimit;
        bytes32 donId;
    }

    struct UserMintRequest {
        uint256 heartbeat;
        address user;
        bool registerKeeper;
        uint256 initLinkDeposit;
        string pincode;
        string isoCode;
    }

    struct WeatherNftInfo {
        uint256 heartbeat;
        uint256 lastFulfilledAt;
        uint256 upkeepId;
        string pincode;
        string isoCode;
    }

    struct MintFunctionReqResponse {
        bytes response;
        bytes err;
    }

    // variables
    uint256 public s_tokenCounter;
    mapping(Weather => string) public s_weatherToTokenURI;
    FunctionsConfig public s_functionsConfig;
    mapping(bytes32 => UserMintRequest) public s_funcReqIdToUserMintReq;
    mapping(bytes32 => MintFunctionReqResponse) public s_funcReqIdToMintFunctionReqResponse;
    mapping(bytes32 => uint256) public s_funcReqIdToTokenIdUpdate;
    uint256 public s_currentMintPrice;
    uint256 public s_stepIncreasePerMint;
    mapping(uint256 => Weather) public s_tokenIdToWeather;
    mapping(uint256 => WeatherNftInfo) public s_weatherNftInfo;
    address public s_link;
    address public s_keeperRegistry;
    address public s_keeperRegistrar;
    uint32 public s_upkeepGaslimit;

    // events
    event WeatherNFTMintRequestSent(address user, string pincode, string isoCode, bytes32 reqId);
    event WeatherNFTMinted(bytes32 reqId, address user, Weather weather);
    event NftWeatherUpdateRequestSend(uint256 tokenId, bytes32 reqId, uint256 upkeepId);
    event NftWeatherUpdated(uint256 tokenId, Weather weather);
}