const networkConfig = {
  43113: {
    name: "avalancheFuji",
    chainId: 43113,
    functionsRouter: "0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0",
    donIdBytes: "0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000",
    donId: "fun-avalanche-fuji-1",
    subId: "15459", // you can replace this with your own chainlink functions subId
    functionsGasLimit: "300000",
    linkToken: "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846",
    keeperRegistry: "0x819B58A646CDd8289275A87653a2aA4902b14fe6",
    keeperRegistrar: "0xD23D3D1b81711D75E1012211f1b65Cc7dBB474e2",
    keeperGaslimit: "700000"
  }
};

const localNetworks = ["hardhat", "localhost"];

module.exports = { networkConfig, localNetworks };
