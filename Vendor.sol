// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import './ERC20.sol';

contract VendorFLUR is Ownership {

   MyERC20 _ERC20;
   address private VOwner;
   uint TokenPerEther = 100;

   event BuyToken(address indexed buyer, uint _value, uint _tokenQty);
   event SellToken(address indexed seller, uint _howMany, uint _amount);
   event WithdrawBalance( address indexed vendor, uint _balance);

   constructor( address ERC20_ ) {

       VOwner = msg.sender;
       _ERC20 = MyERC20(ERC20_);

   }

   function buyToken( ) payable public returns(bool) {

       require( msg.value >= 1 ether, 'Min purchase is 1 ether');

       uint tokenQty = (msg.value / 1 ether) * TokenPerEther;

       uint vendorTokenBal = _ERC20.balanceOf( address(this) );
       require(vendorTokenBal >= tokenQty, 'Insufficient vendor token');

        (bool sent) = _ERC20.transfer(msg.sender, tokenQty );
        require( sent, 'Token transfer failed');

        emit BuyToken( msg.sender, msg.value, tokenQty );

        return true;

    }

    function sellToken( uint howMany ) public payable returns(bool) {

        uint _token = howMany % TokenPerEther;
        require( _token == 0, 'Must sell in multiple of 100');

        uint limitQty = _ERC20.allowance( msg.sender, address(this)  );
        require( limitQty >= howMany, 'Exceeded allowed qty' );

        uint qtyInEther = howMany / TokenPerEther;
        uint vendorBal = (address(this).balance / 1 ether);
        require( vendorBal >= qtyInEther, 'Insufficient vendor balance');

        (bool success) = _ERC20.transferFrom( msg.sender, address(this), howMany);
        require( success, 'Failed in transfer from sender to vendor');

        (bool sent,) = msg.sender.call{value: qtyInEther * 1e18 }(' ');
            require(sent, 'failed in ether sent');
        emit SellToken( msg.sender, howMany, qtyInEther );

        return true;

    }

    function withdrawal() public payable returns(bool) {

        require( msg.sender == VOwner, 'Only Vendor can withdraw');

        uint contractBal = address(this).balance;
        require(contractBal > 0, 'Balance is zero');

        (bool sent,) = msg.sender.call{value: contractBal }('');
        require( sent, 'Failed in withdrawal');

        emit WithdrawBalance(msg.sender, contractBal );

        return true;

    
    }

}
