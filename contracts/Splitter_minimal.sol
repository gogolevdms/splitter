// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Splitter {
    uint public relayerShare;
    uint public payeeShare;

    address public payee;

    constructor(uint relayerShare_, address payee_, uint payeeShare_) payable {
        relayerShare = relayerShare_;
        payeeShare = payeeShare_;

        payee = payee_;
    }

    function forward(address payable relayer) external payable {
        uint payment = msg.value * relayerShare / (relayerShare + payeeShare);
        (bool success, ) = relayer.call{value: payment}("");
        require(success, "Address: unable to send value, relayer may have reverted");

        payment = msg.value - payment;
        (success, ) = payee.call{value: payment}("");
        require(success, "Address: unable to send value, payee may have reverted");
    }

}