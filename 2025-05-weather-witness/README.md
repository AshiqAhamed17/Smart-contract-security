# Weather NFT

This project provides a dynamic NFT system that changes based on real-world weather conditions for specified locations using Chainlink Functions, Automation, and ERC721 standards. Users can mint their weather NFT and automate the weather updates using Chainlink Automation.

## Contest Details

### Stats
- nSLOC: 236
- Complexity Score: 119

[//]: # (contest-details-open)

### About the Project

Weather NFT enables users to mint NFTs tied to specific geographic locations (identified by pincode and ISO country code). These NFTs automatically update to reflect the current weather conditions of their linked location through Chainlink's decentralized oracle network. The project leverages Chainlink Functions to fetch weather data and Chainlink Automation to keep the NFTs up-to-date.

The codebase is primarily built around two main contracts:
- `WeatherNft.sol` - Main contract for minting and managing dynamic weather NFTs
- `WeatherNftStore.sol` - Base contract containing storage variables, events, and data structures

### WeatherNft

This contract allows users to:
- Mint NFTs linked to specific geographic locations
User can mint weather NFT by paying the mint price. The smart contract also allows user to automate the weather updations in order to update the NFT at regular intervals on the basis of heartbeat. The user can specify whether they want to register automation via chainlink automation by passing _registerKeeper as true. They are required to make an initial link deposit which will fund their keeper subscription. A dedicated keeper subcription is made for every NFT having tokenId as the checkData.

- Weather Query
Chainlink functions is utilized to send a request to Open Weather API and fetch the current weather. The WeatherNft takes in user's pincode and isocode to fetch the current weather. The implementation to get the current weather on the basis of pincode and isocode is written in GetWeather.js
Related Links for OpenWeather API:
```
https://openweathermap.org/api/geocoding-api
https://openweathermap.org/current
https://openweathermap.org/weather-conditions
```

- Set up automated weather updates using Chainlink Automation
The checkupkeep and performupkeep function performs the automation task for weather NFT auto updation with the current temperature. The checkupkeep function is triggered by chainlink keepers with the respective tokenId to check for NFT update if interval has passed depicted by heartbeat.
The keepers then call performupkeep function to send a request to chainlink functions to fetch the current weather and update the NFT data.

- Manual Weather Update
A user can also choose to not subscribe to automation and can manually call performupkeep with the tokenId of their NFT and get their NFT updated with the latest data from the chainlink functions request to open weather API.


## WeatherNftStore

This contract contains:
- Storage variables for the WeatherNft system
- Event definitions
- Error declarations
- Data structure definitions

## Minting a Weather NFT

A user calls the `requestMintWeatherNFT` function with:
1. Pincode - postal/zip code of the location
2. ISO country code - country identifier
3. Optional Keeper registration - to automate weather updates
4. Heartbeat interval - frequency of weather updates
5. Initial LINK deposit - for automation services

The minting process involves:
1. Payment of the current mint price (which increases with each mint)
2. Sending a Chainlink Functions request to fetch weather data
3. Chainlink function callback populates the state with the response and error containing the weather data.
3. User calls the fulfillMintRequest function and NFT is minted with the current weather data in response.
4. If requested, a Chainlink Automation upkeep is registered to keep the NFT updated

## Automating Weather Updates

For NFTs with registered automation:
1. Chainlink Keepers check if the heartbeat interval has passed
2. When it's time for an update, the keeper calls `performUpkeep`
3. A new Chainlink Functions request is sent to fetch the current weather
4. When the data arrives, the NFT's weather state is updated

## Weather States

The contract supports the following weather states:
- SUNNY
- CLOUDY
- RAINY
- THUNDERSTORM
- WINDY
- SNOW

Each weather state has an associated image URI that represents the current condition.
The sample URI can be found in the deployment script (deploy/DeployWeatherNft.js)

## Roles in the Project:

1. NFT Owner
   - Users who mint and own Weather NFTs
   - Can transfer ownership of their NFTs

2. Contract Owner
   - Can update Chainlink Functions configuration
   - Can modify gas limits and other system parameters
   - Controls subscription IDs and other administrative settings

[//]: # (contest-details-close)

[//]: # (getting-started-open)

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0`

## Quickstart

```bash
git clone https://github.com/CodeHawks-Contests/2025-05-weather-witness.git
cd weather-witness
```

### Install Dependencies

```bash
forge build
npm i
```

### Set up environment variables
Make a .env file and fill it with the following variables.

- AVAX_FUJI_RPC_URL: RPC Url for Avalanche Fuji Testnet Chain
- PRIVATE_KEY: Your wallet private key
- AVAX_API_KEY: Block explorer's API Key for Avalanche Chain
- OPEN_WEATHER_API_KEY: API Key for Open Weather
- GITHUB_API_TOKEN: API Key for Github in order to create GISTS.
(Note: While creating API Key for Github ensure to select read/write gists)

### Deployment on Avalanche Fuji

```
npx hardhat deploy --network avalancheFuji --tags main
```

### Testing

```bash
source .env
forge test --mt test_weatherNFT_Workflow --fork-url $AVAX_FUJI_RPC_URL --via-ir 
```

### Compiling

```bash
forge build
```

[//]: # (getting-started-close)

[//]: # (scope-open)

# Audit Scope Details

### In Scope:
```
├── functionsSource
│   ├── GetWeather.js
├── src
│   ├── WeatherNft.sol
```

### Compatibilities
All EVM Compatible blockchain given that Chainlink Keeper, Chainlink Automation and all other dependencies are available on the blockchain.

[//]: # (scope-close)

[//]: # (known-issues-open)

# Known Issues

The calculation of weather_enum in GetWeather.js is limited and set to windy in else statement even though multiple weather exists (this is done just to keep limited images).

[//]: # (known-issues-close)
