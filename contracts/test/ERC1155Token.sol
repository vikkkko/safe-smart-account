// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {StorageAccessible} from "../common/StorageAccessible.sol";

/**
 * @title ERC-1155 Test Token
 * @dev Simple ERC1155 token contract for testing purposes.
 */
contract ERC1155Token is StorageAccessible {
    mapping(uint256 => mapping(address => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function uri(uint256) external pure returns (string memory) {
        return "https://example.com";
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory) {
        require(accounts.length == ids.length, "Length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata) external {
        require(to != address(0), "Invalid address");
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "Not authorized");

        balanceOf[id][from] -= value;
        balanceOf[id][to] += value;

        emit TransferSingle(msg.sender, from, to, id, value);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata) external {
        require(to != address(0), "Invalid address");
        require(ids.length == values.length, "Length mismatch");
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "Not authorized");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];

            balanceOf[id][from] -= value;
            balanceOf[id][to] += value;
        }

        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    function mint(address to, uint256 id, uint256 value, bytes calldata) external {
        require(to != address(0), "Invalid address");

        balanceOf[id][to] += value;
        emit TransferSingle(msg.sender, address(0), to, id, value);
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata) external {
        require(to != address(0), "Invalid address");
        require(ids.length == amounts.length, "Length mismatch");

        for (uint256 i = 0; i < ids.length; ++i) {
            balanceOf[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0xd9b67a26 || // ERC1155
            interfaceId == 0x0e89341c; // ERC1155MetadataURI
    }

    function trickFallbackHandler(address fallbackHandler) external {
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            sstore(0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5, fallbackHandler)
        }
        /* solhint-enable no-inline-assembly */
    }
}
