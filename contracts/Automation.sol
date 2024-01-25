// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts@4.9.5/access/Ownable.sol";
import "https://github.com/gelatodigital/automate/blob/master/contracts/integrations/AutomateReady.sol";


// @title Contract to fund sponsor wallets if balance is less than minimum balance
contract Automation is Ownable, AutomateReady {

    address[] public sponsorWallets; // Array of sponsor wallet addresses
    uint256 public minimumBalance; // Minimum balance required in sponsor wallet
    uint256 public fundAmount; // Amount that will be funded to sponsor wallet


     // @notice Constructor
     // @param _automate Address of the Automate contract
     // @param _taskCreator Address of the TaskCreator
     constructor(address _automate, address _taskCreator)
        AutomateReady(_automate, _taskCreator)
    {}

    // @notice Initialize the contract
    // @param _sponsorWallets Array of sponsor wallet addresses
    // @param _minimumBalance Minimum balance required in sponsor wallet
    // @param _fundAmount Amount to be funded to sponsor wallet
    function initializeWallet(address[] calldata _sponsorWallets, uint256 _minimumBalance, uint256 _fundAmount) public onlyOwner {
        sponsorWallets = _sponsorWallets;
        minimumBalance = _minimumBalance;
        fundAmount = _fundAmount;
    }

    // @notice Check if sponsor wallet balance is less than minimum balance
    // @return canExec Boolean value to check if task can be executed
    // @return execPayload Payload to be executed
    function checkSponsorWallet() external view returns(bool canExec,  bytes memory execPayload) {
        uint unfunded = 0;
        canExec = false;
        for(uint i=0;i<sponsorWallets.length;i++){
            if(sponsorWallets[i].balance < minimumBalance) {
                unfunded = unfunded + 1;
            }
        }
        address[] memory unfundedSponsorWallets = new address[](unfunded);
        uint counter = 0;
        for(uint j=0; j<sponsorWallets.length;j++){
            if(sponsorWallets[j].balance < minimumBalance) {
                unfundedSponsorWallets[counter]=sponsorWallets[j];
                counter=counter+1;
            }
        }
        execPayload =  abi.encodeWithSignature("fundSponsorWallet(address[],uint256)",unfundedSponsorWallets,fundAmount);
        if(unfundedSponsorWallets.length > 0){
            canExec = true;
        }
    }

    // @notice Fund sponsor wallet
    // @param unfundedSponsorWallets Array of unfunded sponsor wallet addresses
    // @param amount Amount to be funded to sponsor wallet
    function fundSponsorWallet(address[] calldata unfundedSponsorWallets,uint256 amount) onlyDedicatedMsgSender() external payable returns(bool success) {
        for(uint i=0;i<unfundedSponsorWallets.length;i++){
            if(unfundedSponsorWallets[i].balance < minimumBalance){
                (success,) = payable(unfundedSponsorWallets[i]).call{value: amount}("");
            }
        }
        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);
    }

    // @notice receive function
    receive() external payable{
    }

    // @notice withdraw funds from contract
    function withdrawFunds() onlyOwner external returns (bool success) {
        (success,) = payable(msg.sender).call{value: address(this).balance}("");
    }
}