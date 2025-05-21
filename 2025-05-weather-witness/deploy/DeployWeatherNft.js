const { ethers, network } = require("hardhat");
const fs = require("fs");
const { networkConfig, localNetworks } = require("../helper-hardhat-config");
const { verifyContract } = require("../utils/verifyContract");
const { getEncryptedSecretsUrl } = require("../utils/generateEncryptedSecret");
require("dotenv").config();

module.exports = async ({ getNamedAccounts, deployments }) => {
  const chainId = network.config.chainId;
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;

  const source = fs.readFileSync("./functionsSource/GetWeather.js").toString();
  let secretsEncrypted;
  let conf;
  const weathers = [0, 1, 2, 3, 4, 5];
  const weatherURI = [
    "ipfs://bafkreif52aceqnvitpjb6twotibvtyi2mf4iey734lmmadbrxmykwfu3my",
    "ipfs://bafkreidt3ybfli2nthf6u2gtujmarvqi54hf2gk2l3wvq344sjvitbcklq",
    "ipfs://bafkreigcmkxjwtl3kixa32j36y7fq5zwfov4mv4sh2sjmejqpi253wq2i4",
    "ipfs://bafkreign7pr3rsevvftkqvjllf5sv4thfqbxzxd4wg22bkeqtqfynum774",
    "ipfs://bafkreih5go3rg2ulfjowrmum2fqbv6mwptlbhg47taml6zmln3h56vloe4",
    "ipfs://bafkreie3x4z3rplwofdljwhvxrfnvkxbkqwvbxn7wr6vfbtkz2tyofqq54"
  ];
  const currentMintPrice = ethers.utils.parseEther("0.0001");
  const stepIncreasePerMint = ethers.utils.parseEther("0.00001");
  let functionsRouter;
  let functionsConfig;
  let linkToken;
  let keeperRegistry;
  let keeperRegistrar;
  let upkeepGaslimit;

  conf = 3;

  const secrets = { apiKey: process.env.OPEN_WEATHER_API_KEY };
  secretsEncrypted = await getEncryptedSecretsUrl(secrets);
  fs.writeFileSync("./encryptedSecretsUrl.txt", secretsEncrypted);

  functionsRouter = networkConfig[chainId].functionsRouter;
  functionsConfig = {
    source: source,
    encryptedSecretsURL: secretsEncrypted,
    subId: networkConfig[chainId].subId,
    gasLimit: networkConfig[chainId].functionsGasLimit,
    donId: networkConfig[chainId].donIdBytes
  };
  linkToken = networkConfig[chainId].linkToken;
  keeperRegistry = networkConfig[chainId].keeperRegistry;
  keeperRegistrar = networkConfig[chainId].keeperRegistrar;
  upkeepGaslimit = networkConfig[chainId].keeperGaslimit;

  const args = [
    weathers,
    weatherURI,
    functionsRouter,
    functionsConfig,
    currentMintPrice,
    stepIncreasePerMint,
    linkToken,
    keeperRegistry,
    keeperRegistrar,
    upkeepGaslimit
  ];
  const weatherNftContract = await deploy("WeatherNft", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: conf,
  });

  console.log("Deployed at: ", weatherNftContract.address);

  if (!localNetworks.includes(network.name) && process.env.AVAX_API_KEY) {
    await verifyContract(weatherNftContract.address, args);
  }
};

module.exports.tags = ["main"];
