// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Corn} from "../src/Corn.sol";
import {CornDEX} from "../src/CornDEX.sol";
import {Lending} from "../src/Lending.sol";
import {MovePrice} from "../src/MovePrice.sol";

contract DeployContracts is Script {
    function run() external {
        // Get deployer address
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployer);

        // Deploy Corn token
        Corn cornToken = new Corn();
        
        // Deploy CornDEX with Corn token address
        CornDEX cornDEX = new CornDEX(address(cornToken));
        
        // Deploy Lending with CornDEX and Corn token addresses
        Lending lending = new Lending(address(cornDEX), address(cornToken));
        
        // Deploy MovePrice with CornDEX and Corn token addresses
        MovePrice movePrice = new MovePrice(address(cornDEX), address(cornToken));

        // Local network setup (equivalent to Hardhat's localhost)
        if (block.chainid == 31337) {
            // Give ETH to movePrice contract (10000 ETH)
            payable(address(movePrice)).transfer(10_000 ether);
            
            // Mint CORN to movePrice contract (10000 CORN)
            cornToken.mintTo(address(movePrice), 10_000 ether);
            
            // Give CORN and ETH to deployer
            cornToken.mintTo(deployer, 1_000_000 ether);
            payable(deployer).transfer(100 ether);
            
            // Transfer ownership and approve
            cornToken.transferOwnership(address(lending));
            cornToken.approve(address(cornDEX), 1_000_000 ether);
            
            // Initialize CornDEX
            cornDEX.init{value: 1_000_000 ether}(1_000_000 ether);
        }

        vm.stopBroadcast();

        // Log deployed addresses
        console.log("Corn deployed to:", address(cornToken));
        console.log("CornDEX deployed to:", address(cornDEX));
        console.log("Lending deployed to:", address(lending));
        console.log("MovePrice deployed to:", address(movePrice));
    }
}
