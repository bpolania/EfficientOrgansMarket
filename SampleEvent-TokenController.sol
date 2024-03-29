pragma solidity ^0.4.6;

/*
    Copyright 2017, Boris Polania

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title Event
/// @author Boris
/// @dev This contract controls the issuance of tickets tokens for the TokenMaster
///  Contract. This version specifically acts as a Event manager for selling tickets,
/// but it can be customized for any variety of purposes.
/// @dev This token contract's is based on Jordi Baylina's Campaign contract (https://github.com/Giveth/minime/blob/master/contracts/SampleCampaign-TokenController.sol)

import "TokenMaster.sol";


/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {
    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner { require (msg.sender == owner); _; }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() { owner = msg.sender;}

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}


/// @dev This is designed to control the issuance of a MiniMe Token for a
///  non-profit Event. This contract effectively dictates the terms of the
///  funding round.

contract Market is TokenController, Owned {

    uint public maximumNumberOfDonors;  // In wei
    MiniMeToken public tokenContract;   // The new token for this Event

/// @notice 'Event()' initiates the Event by setting its funding
/// parameters
/// @dev There are several checks to make sure the parameters are acceptable
/// @param _startSaleTime The UNIX time that the Event will be able to
/// start selling tickets
/// @param _endSaleTime The UNIX time that the Event will stop being able
/// to sell tickets
/// @param _maximumNumberOfTickets the Maximum amount of tickets that the Event can
/// sell
/// @param _vaultAddress The address that will store the donated funds
/// @param _tokenAddress Address of the token contract this contract controls

    function Market(
        uint _maximumNumberOfDonors,
        address _vaultAddress,
        address _tokenAddress

    ) {
        require ((_maximumNumberOfTickets <= 10000) &&        // The Beta is limited
            (_vaultAddress != 0));                    // To prevent burning ETH
        maximumNumberOfDonors = _maximumNumberOfDonors;
        tokenContract = TokenMaster(_tokenAddress);// The Deployed Token Contract
        vaultAddress = _vaultAddress;
    }

/// @dev The fallback function is called when ether is sent to the contract, it
/// simply calls `doPayment()` with the address that sent the ether as the
/// `_owner`. Payable is a required solidity modifier for functions to receive
/// ether, without this modifier functions will throw if ether is sent to them

    function ()  payable {
        doPayment(msg.sender);
    }

/////////////////
// TokenController interface
/////////////////

/// @notice `proxyPayment()` allows the caller to send ether to the Event and
/// have the tokens created in an address of their choosing
/// @param _owner The address that will hold the newly created tokens

    function proxyPayment(address _owner) payable returns(bool) {
        doPayment(_owner);
        return true;
    }

/// @notice Notifies the controller about a transfer, for this Event all
///  transfers are allowed by default and no extra notifications are needed
/// @param _from The origin of the transfer
/// @param _to The destination of the transfer
/// @param _amount The amount of the transfer
/// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) returns(bool) {
        return true;
    }

/// @notice Notifies the controller about an approval, for this Event all
///  approvals are allowed by default and no extra notifications are needed
/// @param _owner The address that calls `approve()`
/// @param _spender The spender in the `approve()` call
/// @param _amount The amount in the `approve()` call
/// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool)
    {
        return true;
    }


/// @dev `doPayment()` is an internal function that sends the ether that this
///  contract receives to the `vault` and creates tokens in the address of the
///  `_owner` assuming the Event is still accepting funds
/// @param _owner The address that will hold the newly created tokens

    function doPayment(address _owner) internal {

// First check that the Event is allowed to receive this donation
        require ((tokenContract.controller() != 0) &&           // Extra check
            (msg.value != 0));

//Track how much the Event has collected
        totalCollected += msg.value;

//Send the ether to the vault
        require (vaultAddress.send(msg.value));

// Creates an equal amount of tokens as ether sent. The new tokens are created
//  in the `_owner` address
        require (tokenContract.generateTokens(_owner, msg.value));

        return;
    }

/// @notice `finalizeFunding()` ends the Event by calling setting the
///  controller to 0, thereby ending the issuance of new tokens and stopping the
///  Event from receiving more ether
/// @dev `finalizeFunding()` can only be called after the end of the funding period.

    function finalizeFunding() {
        require(now >= endSaleTime);
        tokenContract.changeController(0);
    }


/// @notice `onlyOwner` changes the location that ether is sent
/// @param _newVaultAddress The address that will receive the ether sent to this
///  Event
    function setVault(address _newVaultAddress) onlyOwner {
        vaultAddress = _newVaultAddress;
    }

}
