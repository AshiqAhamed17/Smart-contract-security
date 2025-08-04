// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";
import { console2 } from "forge-std/Console2.sol";
import {WeatherNft, WeatherNftStore} from "src/WeatherNft.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {Vm} from "forge-std/Vm.sol";

contract WeatherNftForkTest is Test {
    WeatherNft weatherNft;
    LinkTokenInterface linkToken;
    address functionsRouter;
    address user = makeAddr("user");

    event WeatherNFTMintRequestSent(address user, string pincode, string isoCode, bytes32 requestId);

    function setUp() external {
        // // You can replace the weather nft contract with your own deployed contract
        // weatherNft = WeatherNft(0x4fF356bB2125886d048038386845eCbde022E15e);
        // linkToken = LinkTokenInterface(0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846);
        // functionsRouter = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;
        // vm.deal(user, 1000e18);
        // deal(address(linkToken), user, 1000e18);

        // // fund weather nft sub
        // vm.prank(user);
        // linkToken.transferAndCall(functionsRouter, 100e18, abi.encode(15459));
    }

    function test_weatherNFT_Workflow() public {
        string memory pincode = "125001";
        string memory isoCode = "IN";
        bool registerKeeper = true;
        uint256 heartbeat = 12 hours;
        uint256 initLinkDeposit = 5e18;
        uint256 tokenId = weatherNft.s_tokenCounter();

        vm.startPrank(user);
        linkToken.approve(address(weatherNft), initLinkDeposit);
        vm.recordLogs();
        weatherNft.requestMintWeatherNFT{value: weatherNft.s_currentMintPrice()}(
            pincode,
            isoCode,
            registerKeeper,
            heartbeat,
            initLinkDeposit
        );
        vm.stopPrank();

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 reqId;
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("WeatherNFTMintRequestSent(address,string,string,bytes32)")) {
                (, , , reqId) = abi.decode(logs[i].data, (address, string, string, bytes32));
                break;
            }
        }
        assert(reqId != bytes32(0));

        (
            uint256 reqHeartbeat,
            address reqUser,
            bool reqRegisterKeeper,
            uint256 reqInitLinkDeposit,
            string memory reqPincode,
            string memory reqIsoCode
        ) = weatherNft.s_funcReqIdToUserMintReq(reqId);
        assertEq(reqUser, user);
        assertEq(reqHeartbeat, heartbeat);
        assertEq(reqInitLinkDeposit, initLinkDeposit);
        assertEq(reqIsoCode, isoCode);
        assertEq(reqPincode, pincode);
        assertEq(reqRegisterKeeper, registerKeeper);

        vm.prank(functionsRouter);
        bytes memory weatherResponse = abi.encode(WeatherNftStore.Weather.RAINY);
        weatherNft.handleOracleFulfillment(reqId, weatherResponse, "");

        vm.prank(user);
        weatherNft.fulfillMintRequest(reqId);

        (
            uint256 infoHeartbeat,
            uint256 infoLastFulfilledAt,
            uint256 infoUpkeepId,
            string memory infoPincode,
            string memory infoIsoCode
        ) = weatherNft.s_weatherNftInfo(tokenId);
        assertEq(infoHeartbeat, heartbeat);
        assertEq(infoIsoCode, isoCode);
        assertEq(infoLastFulfilledAt, block.timestamp);
        assertEq(infoPincode, pincode);
        assert(infoUpkeepId > 0);
        assertEq(uint8(weatherNft.s_tokenIdToWeather(tokenId)), uint8(WeatherNftStore.Weather.RAINY));

        // getting token uri
        string memory tokenURI = weatherNft.tokenURI(tokenId);

        // automation check
        bytes memory encodedTokenId = abi.encode(tokenId);
        (bool weatherUpdateNeeded, ) = weatherNft.checkUpkeep(encodedTokenId);
        assert(weatherUpdateNeeded == false);

        // time travelling to reach heartbeat for weather update
        vm.warp(block.timestamp + heartbeat);
        (bool weatherUpdateNeeded2, bytes memory performData) = weatherNft.checkUpkeep(encodedTokenId);
        assert(weatherUpdateNeeded2 == true);
        assertEq(performData, encodedTokenId);

        // chainlink keeper nodes call the performupkeep func with the encoded tokenid in order to request for current weather
        // the request is sent to chainlink functions with the user's pincode and isocode, to update the current weather for nft
        vm.recordLogs();
        weatherNft.performUpkeep(performData);

        // fetching request id
        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 tokenIdToUpdate;
        bytes32 tokenIdUpdateReq;
        for (uint256 i; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("NftWeatherUpdateRequestSend(uint256,bytes32,uint256)")) {
                (tokenIdToUpdate, tokenIdUpdateReq) = abi.decode(entries[i].data, (uint256, bytes32));
                break;
            }
        }

        assert(tokenIdUpdateReq != bytes32(0));
        assertEq(tokenIdToUpdate, tokenId);
        assertEq(weatherNft.s_funcReqIdToTokenIdUpdate(tokenIdUpdateReq), tokenId);

        vm.prank(functionsRouter);
        bytes memory newWeatherResponse = abi.encode(WeatherNftStore.Weather.CLOUDY);
        weatherNft.handleOracleFulfillment(tokenIdUpdateReq, newWeatherResponse, "");
        assertEq(uint8(weatherNft.s_tokenIdToWeather(tokenId)), uint8(WeatherNftStore.Weather.CLOUDY));

        string memory newTokenURI = weatherNft.tokenURI(tokenId);
        assertNotEq(tokenURI, newTokenURI);
    }

    ///// MY TESTS ////////

    function testAbiEncodePackedCollision() public {
        bytes memory packed1 = abi.encodePacked("abc", "def");
        bytes memory packed2 = abi.encodePacked("abcd", "ef");

        assertEq(keccak256(packed1), keccak256(packed2), "Hash collision detected");
        
        console.log("Packed1 hash: ");
        console.logBytes32(keccak256(packed1)); //0xacd0c377fe36d5b209125185bc3ac41155ed1bf7103ef9f0c2aff4320460b6df

        console.log("Packed2 hash: ");
        console.logBytes32(keccak256(packed2)); //0xacd0c377fe36d5b209125185bc3ac41155ed1bf7103ef9f0c2aff4320460b6df
    }

    function testEmptyLocationTriggersRequest() public {
    string memory emptyPincode = "";
    string memory emptyIsoCode = "";

    // Call as a regular user with 0.01 ETH (assuming current mint price)
    weatherNft.requestMintWeatherNFT{value: 0.01 ether}(
        emptyPincode,
        emptyIsoCode,
        false,      // no keeper
        0,          // heartbeat
        0           // LINK
    );

    // Expectation: Oracle request is still triggered even though input is empty
    // This can cause failures or wasted LINK usage
}

function testMintAllowsEmptyPincodeAndIsoCode() public {
    string memory emptyPincode = "";
    string memory emptyIsoCode = "";

    // Expect the function NOT to revert on bad input
    vm.expectEmit(true, true, true, true);
    emit WeatherNFTMintRequestSent(
        address(this), // sender
        emptyPincode,
        emptyIsoCode,
        bytes32(0) // request ID will be overwritten in actual call, so allow wildcard if needed
    );

    weatherNft.requestMintWeatherNFT{value: 0.01 ether}(
        emptyPincode,
        emptyIsoCode,
        false,      // don't register keeper
        0,          // heartbeat
        0           // LINK deposit
    );
}

}