const { run } = require("hardhat")

async function verifyContract(contractAddress, args) {
    try {
        console.log("Verification in progress...")

        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: args
        })

        console.log("Verified!");
    }
    catch(err) {
        if (err.message.toLowerCase().includes("already verified")) {
            console.log("Contract is already verified!");
        }
        else {
            console.log(err);
        }
    }
}

module.exports = { verifyContract }