// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/TicketNFT.sol";
import "openzeppelin-contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @title TicketNFT Foundry Tests
/// @notice Exhaustive tests for TicketNFT (initialize, mint, tokenURI, enumeration, access control)
contract TicketNFTTest is Test {
    TicketNFT internal ticket;
    address internal admin = address(0xABCD);
    address internal user1 = address(0xBEEF);
    address internal user2 = address(0xCAFE);
    string internal name = "MatchTicket";
    string internal symbol = "MTKT";
    string internal baseURI = "ipfs://cid/";

    /// @notice Deploy and initialize a fresh TicketNFT before each test
    function setUp() public {
        ticket = new TicketNFT();
        // Initialize as if called by any account
        ticket.initialize(name, symbol, baseURI, admin);
    }

    /// @notice Test initialize sets name, symbol, roles, and starting tokenId
    function testInitializeProperties() public {
        // Check ERC721 name and symbol
        assertEq(ticket.name(), name, "Name should be set");
        assertEq(ticket.symbol(), symbol, "Symbol should be set");
        // Check roles: admin must have DEFAULT_ADMIN_ROLE and MINTER_ROLE
        bytes32 adminRole = ticket.DEFAULT_ADMIN_ROLE();
        bytes32 minterRole = ticket.MINTER_ROLE();
        assertTrue(ticket.hasRole(adminRole, admin), "Admin must have admin role");
        assertTrue(ticket.hasRole(minterRole, admin), "Admin must have minter role");
    }

    /// @notice Test that mintWithURI reverts if caller lacks MINTER_ROLE
    function testMintRevertsWithoutRole() public {
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSignature("AccessControl: account %s is missing role %s", user1, ticket.MINTER_ROLE())
        );
        ticket.mintWithURI(user1, "1.json");
    }

    /// @notice Test successful mint, tokenId increments, ownership, and tokenURI
    function testMintAndTokenURI() public {
        // Prank as admin (minter)
        vm.prank(admin);
        uint256 tid = ticket.mintWithURI(user1, "1.json");
        // First tokenId should be 1
        assertEq(tid, 1, "First tokenId should be 1");
        // Owner and balance
        assertEq(ticket.ownerOf(tid), user1, "Owner must be user1");
        assertEq(ticket.balanceOf(user1), 1, "Balance must be 1");
        // tokenURI should be baseURI + uri
        string memory expected = string.concat(baseURI, "1.json");
        assertEq(ticket.tokenURI(tid), expected, "tokenURI must concatenate baseURI and metadata"
        );
        // Mint second token
        vm.prank(admin);
        uint256 tid2 = ticket.mintWithURI(user2, "ticket2.json");
        assertEq(tid2, 2, "Second tokenId should be 2");
    }

    /// @notice Test enumeration (totalSupply, tokenByIndex, tokenOfOwnerByIndex)
    function testEnumeration() public {
        // Mint three tokens to user1
        vm.startPrank(admin);
        ticket.mintWithURI(user1, "a.json"); // id=1
        ticket.mintWithURI(user1, "b.json"); // id=2
        ticket.mintWithURI(user1, "c.json"); // id=3
        vm.stopPrank();

        // totalSupply should be 3
        assertEq(ticket.totalSupply(), 3, "totalSupply should equal 3");
        // tokenByIndex ordering
        for (uint256 i = 0; i < 3; i++) {
            uint256 id = ticket.tokenByIndex(i);
            assertTrue(id >= 1 && id <= 3, "tokenByIndex ID out of range");
        }
        // tokenOfOwnerByIndex for user1
        for (uint256 j = 0; j < 3; j++) {
            assertEq(
                ticket.tokenOfOwnerByIndex(user1, j),
                j + 1,
                "tokenOfOwnerByIndex should return sequential IDs"
            );
        }
    }

    /// @notice Test supportsInterface covers ERC165, ERC721, ERC721Enumerable, AccessControl
    function testSupportsInterface() public {
        // ERC165
        assertTrue(ticket.supportsInterface(0x01ffc9a7), "Should support ERC165");
        // ERC721
        assertTrue(ticket.supportsInterface(0x80ac58cd), "Should support ERC721");
        // ERC721Enumerable
        assertTrue(ticket.supportsInterface(0x780e9d63), "Should support ERC721Enumerable");
        // AccessControl
        assertTrue(ticket.supportsInterface(0x7965db0b), "Should support AccessControl");
    }
    
    /// @notice Test that tokenURI reverts for nonexistent token
    function testTokenURIRevertsForNonexistent() public {
        // tokenId 999 does not exist
        vm.expectRevert("ERC721: invalid token ID");
        ticket.tokenURI(999);
    }
}
