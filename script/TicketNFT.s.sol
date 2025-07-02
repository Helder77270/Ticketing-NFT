// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/TicketNFT.sol";

contract DeployTicketNFT is Script {
    function run() external {
        // 1. Passez en mode broadcast pour signer les tx
        vm.startBroadcast();

        // 2. Déployez l'implémentation (logic contract)
        TicketNFT impl = new TicketNFT();

        // 3. Encodez l'appel à initialize(name, symbol, baseURI, admin)
        bytes memory initData = abi.encodeWithSelector(
            TicketNFT.initialize.selector,
            "MatchTicket",       // name
            "MTKT",              // symbol
            "ipfs://Qm",         // baseURI
            msg.sender           // admin (celui qui lance le script)
        );

        // 4. Déployez le proxy ERC-1967 avec l'implémentation et l'initData
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            initData
        );

        // 5. Cast du proxy pour interagir comme TicketNFT
        TicketNFT ticket = TicketNFT(address(proxy));

        console.log("TicketNFT proxy deployed at:", address(ticket));

        vm.stopBroadcast();
    }
}