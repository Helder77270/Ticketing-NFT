// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title TicketNFT
 * @dev ERC-721 NFT contract for ticketing with upgradeability and role-based access control
 */
contract TicketNFT is ERC721EnumerableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Incremental token ID counter, starts at 1
    uint256 private _nextTokenId;

    // Base URI for token metadata (used by _baseURI)
    string private _baseTokenURI;

    // Custom mapping for token-specific metadata URIs
    mapping(uint256 => string) private ticketMetadataUri;

    /**
     * @notice Initialize the TicketNFT contract with name, symbol, base URI, and admin
     * @dev Grants DEFAULT_ADMIN_ROLE and MINTER_ROLE to the admin, sets starting ID and base URI
     * @param name Name of the ERC-721 token collection
     * @param symbol Symbol of the ERC-721 token collection
     * @param baseURI Base URI for token metadata (e.g., IPFS CID)
     * @param admin Address to receive admin and minter roles
     */
    function initialize(string calldata name, string calldata symbol, string calldata baseURI, address admin)
        external
        initializer
    {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);

        _nextTokenId = 1;
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Mint a new ticket NFT to a specified address with custom metadata URI
     * @dev Only accounts with MINTER_ROLE can call this function
     * @param to Recipient address for the newly minted NFT
     * @param uri Full metadata URI for the token (overrides base URI)
     * @return tokenId The ID of the newly minted token
     */
    function mintWithURI(address to, string calldata uri) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @notice Internal function to set the metadata URI for a given token
     * @dev Stores the URI in a mapping instead of using ERC721URIStorage
     * @param tokenId ID of the token to set metadata for
     * @param uri Metadata URI to associate with the token
     */
    function _setTokenURI(uint256 tokenId, string calldata uri) internal {
        ticketMetadataUri[tokenId] = uri;
    }

    /**
     * @notice Returns the base URI set for the contract
     * @dev Used by {tokenURI} to construct full token URI when not overridden
     * @return Base URI string
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Returns the whole URI link to IPFS or DB
     * @dev Used by {tokenURI} to construct full token URI when not overridden
     * @return Base URI string
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, ticketMetadataUri[tokenId]) : "";
    }

    /**
     * @notice Query if a contract implements an interface, according to ERC-165
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return True if the contract implements the requested interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Restrict upgradeability: only accounts with DEFAULT_ADMIN_ROLE can upgrade
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
