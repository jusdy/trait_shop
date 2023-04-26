// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @notice Simple multi-sig Wallet.
*/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Wallet {
    bool isInit;

    uint256 public threshold;
    uint256 private transactionIndex;
    uint256 private updatethresholdIndex;
    uint256 private removeOwnerIndex;
    uint256 private addOwnerIndex;

    address[] public owners;

    mapping(address => bool) isOwner;
    mapping(address => mapping(uint256 => bool)) transactionSigners;

    event NewTransaction(address to, address collection, uint256 id, address sender);
    event NewDeposit(address _sender, uint256 _value);

    struct Transaction {
        address to;
        address collection;
        uint256 id;
        uint256 index;
        uint256 signatures;
        bool approved;
    }

    Transaction[] transactions;

    constructor(address[] memory _owners, uint256 _threshold) {
        require(!isInit, "wallet in use");
        require(_owners.length > 0, "There needs to be more than 0 owners");
        require(_threshold <= _owners.length, "threshold exceeds owners");
        require(_threshold > 0, "threshold needs to be more than 0");
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(!isOwner[owner], "Address already an owner");
            require(owner != address(this), "This address can't be owner");
            require(owner != address(0), "Address 0 can't be owner");
            owners.push(owner);
            isOwner[owner] = true;
        }
        threshold = _threshold;
        isInit = true;
    }

    receive() external payable {
        emit NewDeposit(msg.sender, msg.value);
    }

    // checks if the caller is an owner.
    modifier onlyOwners() {
        require(isOwner[msg.sender], "Not owner");

        _;
    }

    /**
     * @notice creates a transaction request and adds one signature.
     * @param _to - receiver of the transaction.
     */
    function transactionRequest(address _to, address _collection, uint256 _id)
        external
        onlyOwners
    {
        require(_to != address(0), "address zero not supported");
        require(IERC721(_collection).ownerOf(_id) == address(this), "wallet does not have NFT");

        transactions.push(
            Transaction({
                to: _to,
                collection: _collection,
                id: _id,
                index: transactionIndex,
                signatures: 0,
                approved: false
            })
        );
        transactionIndex += 1;
    }

    /**
     * @notice approves a transaction after reaching the threshold
     * @param _index index of the transaction.
     */
    function transactionApproval(uint256 _index) external onlyOwners {
        require(
            transactionSigners[msg.sender][_index] == false,
            "You already signed this transaction"
        );
        Transaction storage t = transactions[_index];
        require(!t.approved, "Transaction already approved");
        t.signatures += 1;
        transactionSigners[msg.sender][_index] = true;
        if (t.signatures >= threshold) {
            // (bool sent, ) = t.to.call{value: t.value}("");
            IERC721(t.collection).safeTransferFrom(address(this), t.to, t.id);
            // require(sent, "Transaction failed");
            t.approved = true;
            emit NewTransaction(t.to, t.collection, t.id, msg.sender);
        }
    }

    /**
     * @return returns an array of the indexes of the pending transactions.
     */
    function pendingTransactionsIndex()
        private
        view
        returns (uint256[] memory)
    {
        uint256 counter;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].approved == false) {
                counter += 1;
            }
        }
        uint256[] memory result = new uint256[](counter);
        uint256 index;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].approved == false) {
                result[index] = i;
                index += 1;
            }
        }
        return result;
    }

    /**
     * @return an array of pending transactions in struct format.
     */
    function pendingTransactionsData()
        external
        view
        onlyOwners
        returns (Transaction[] memory)
    {
        uint256[] memory pendingTr = pendingTransactionsIndex();
        Transaction[] memory t = new Transaction[](pendingTr.length);
        for (uint256 i = 0; i < pendingTr.length; i++) {
            t[i] = transactions[pendingTr[i]];
        }
        return t;
    }


    ///@return uint of total active owners.
    function totalOwners() public view returns (uint256) {
        uint256 result;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] != address(0)) {
                result += 1;
            }
        }
        return result;
    }

    /// @return an array of the addresses of the owners.
    function getOwnersAddress() external view returns (address[] memory) {
        require(owners.length > 0, "0 owners not valid, ERROR!");
        uint256 counter;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] != address(0)) {
                counter += 1;
            }
        }
        address[] memory result = new address[](counter);
        uint256 index;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] != address(0)) {
                result[index] = owners[i];
                index += 1;
            }
        }
        return result;
    }
}
