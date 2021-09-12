// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
/**
 * @title Splitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 */
contract Splitter is Ownable {
    uint256 private _relayerShare;
    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address payable[] private _payees;

    event PayeeAdded(address account, uint256 shares);
    event PayeeUpdated(uint256 payeeId, address oldPayee, uint256 oldShares, address newPayee, uint256 newShares);
    event PayeeRemoved(address account, uint256 shares);

    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    /**
     * @dev Creates an instance of `Splitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(uint256 relayerShare_, address payable[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "Splitter: payees and shares length mismatch");
        require(payees.length > 0, "Splitter: no payees");

        _relayerShare = relayerShare_;
        _totalShares = _totalShares + relayerShare_;

        for (uint256 i = 0; i < payees.length; i++) {
            addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        _releaseInternal(payable(_msgSender()), _relayerShare);

        for (uint256 i = 0; i < _payees.length; i++) {
            _release(_payees[i]);
        }

        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the relayer share.
     */
    function relayerShare() public view returns (uint256) {
        return _relayerShare;
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function _release(address payable account) internal {
        _releaseInternal(account, _shares[account]);
    }

    function _releaseInternal(address payable account, uint256 share) internal {
        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = (totalReceived * share) / _totalShares - _released[account];

        _released[account] = _released[account] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(account, payment);

        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Add a new payee to the contract (for only owner).
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function addPayee(address payable account, uint256 shares_) public onlyOwner {
        require(account != address(0), "PaymentSplitter: account is the zero address");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;

        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev Update a payee to the contract (for only owner).
     * @param payeeId The payee Id in array of the payee to update.
     * @param newPayee The address of the payee to update.
     * @param newShares_ The number of shares owned by the payee.
     */
    function updatePayee(uint256 payeeId, address payable newPayee, uint256 newShares_) public onlyOwner {
        require(newPayee != address(0), "PaymentSplitter: newPayee is the zero address");
        require(payeeId < _payees.length, "PaymentSplitter: payeeId is more than payees length");

        address oldPayee = _payees[payeeId];
        _payees[payeeId] = newPayee;

        uint256 oldShares = _shares[_payees[payeeId]];
        _totalShares = _totalShares - oldShares + newShares_;
        _shares[newPayee] = newShares_;

        emit PayeeUpdated(payeeId, oldPayee, oldShares, newPayee, newShares_);
    }
}
