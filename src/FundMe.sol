// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


error FundMe__NotOwner();

contract FundMe {

   //This here is similar to extension in dart
    using PriceConverter for  uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18;
    address[] private s_funders; // private are gas efficients, so we use getters to get their details
    //similar to final in dart
    address private immutable i_owner;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;
    constructor(address priceFeed){
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable  {
        require(msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD, "Did't send enough ETH");

        //msg.sender is a global variable to
        // get the address that called this function
        s_funders.push(msg.sender);

        s_addressToAmountFunded[msg.sender] += msg.value;
    }

     function getVersion() public view returns (uint256){
        return s_priceFeed.version();
    }

       modifier onlyOwner(){       
        // what happens here is it first checks the
        // required function and if it passes
        // _; tells it to continue to code
        // require(msg.sender == i_owner, "Sender is not owner");  
        if(msg.sender != i_owner){
            revert FundMe__NotOwner();
        }    
         _;  

    }

    
    function withdraw() public onlyOwner {
        
        // looper thru the addresses and setting them to 0
        for(uint256 funderIndex; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // resetting the array
        s_funders = new address[](0);

        // withdrawing funds... there are 3 methods
        //transfer
        //send      

        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length; 

        for(uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(callSuccess, "Call failed");
    }

 

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * view / pure functions (getters)
     * view is used to get something from storage
     * pure is used to maybe return something 
     * in memory/not in storage
     */

    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256){
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns(address){
        return s_funders[index];
    }

    function getOwner() external view returns(address){
        return i_owner;
    }
}