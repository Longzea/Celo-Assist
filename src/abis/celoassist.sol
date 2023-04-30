// SPDX-License-Identifier: MIT

/**

@title CeloAssist
@dev This contract provides functionality to create and manage payees, as well as store chat messages.
@author Longzea
@notice Use this contract at your own risk.

*/

pragma solidity ^0.8.3;
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CeloAssist{
    // Declaring variables.
    uint internal payeeLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    // Created two event for the contract
    event PayeeCreated(address indexed owner, string payeeFullName, string payeeDescription, string networkType, uint payeeGasFee);
    event PayeeDeleted(address indexed owner, uint payeeId);
     
    
    /**
     @dev Struct to create payee details.
     @param owner The address of the payee owner.
     @param payeeFullName The full name of the payee.
     @param payeeDescription The description of the payee.
     @param networkType The network type of the payee.
     @param payeeGasFee The gas fee required to fund the payee.
    */
    struct PayeeDetails {
        address payable  owner;
        string payeeFullName;
        string payeeDescription;
        string networkType;
        uint payeeGasFee;   
    }

    /**
     @dev Struct to create chats.
     @param owner The address of the chat owner.
     @param message The message of the chat.
     */
    struct Chat{
        address owner;
        string  message;
    }

    // mapping to store payee details
    mapping (uint => PayeeDetails) internal payee;

    // mapping to store chats
    mapping(uint => Chat[]) internal chats;


    /**
     @dev Function to create a payee.
     @param _payeeFullName The full name of the payee.
     @param _payeeDescription The description of the payee.
     @param _networkType The network type of the payee.
     @param _payeeGasFee The gas fee required to fund the payee.
     Requirements:
     - `_payeeFullName` cannot be empty.
     - `_payeeDescription` cannot be empty.
     - `_payeeGasFee` must be greater than 0.
    */
    function createPayee(string memory _payeeFullName, string memory _payeeDescription, string memory _networkType, uint _payeeGasFee   ) public {
        require(bytes(_payeeFullName).length > 0, "Payee full name cannot be empty"); 
        require(bytes(_payeeDescription).length > 0, "Payee description cannot be empty");
        require(_payeeGasFee > 0, "Payee gas fee must be greater than 0");
        payee[payeeLength] = PayeeDetails({owner : payable(msg.sender), payeeFullName : _payeeFullName,
        payeeDescription : _payeeDescription, networkType : _networkType,
        payeeGasFee :  _payeeGasFee   });
        payeeLength++;
        emit PayeeCreated(msg.sender, _payeeFullName, _payeeDescription, _networkType, _payeeGasFee); //Emit the payeeCreated event for when an event is created
}


    /**
        @dev Fetches payee details based on its unique identifier.
        @param _id The unique identifier of the payee.
        @return Returns a tuple containing payee details such as the owner address, payee name, payee description, network type and payee gas fee.
        @notice This function is a read-only function and can be called from any contract or externally.
        warning The _id parameter must be a valid and existing payee identifier, otherwise an error may occur.
    */
    function fetchPayeeById(uint _id) public view returns (
        address,
        string memory,
        string memory,
        string memory,
        uint
        
    ) {
        return (
            payee[_id].owner,
            payee[_id].payeeFullName, 
            payee[_id].payeeDescription,
            payee[_id].networkType,
            payee[_id].payeeGasFee
        );
    }

    /**

        @dev Function to allow a payee to delete their request using its ID.
        @param id The ID of the payee request to delete.
        require The ID is valid.
        require The sender is the owner of the payee request.
        return void
        emit PayeeDeleted(msg.sender, id) when the payee request is deleted.
    */ 
    function deletePayeeRequest(uint id) public {
        require(id < payeeLength, "Invalid payee ID"); // Check if the payee ID exists
        require(msg.sender == payee[id].owner, "Please ensure you are the owner this request");
        delete payee[id];
        emit PayeeDeleted(msg.sender, id); // emitted event when a payeeRequest is deleted
    }

     
        /**
            @dev Function to fund a payee with the required gas fee.
            @param _index The index of the payee requesting to be funded.
        **/
    function fundPayee(uint _index) public payable  {
        uint256 amount = payee[_index].payeeGasFee; 
        require(amount > 0, "Invalid amount");// check to ensure that the gas fee needed is greater than zero.
        //Check to make sure the payer has sufficient balance to cover the gas fee
        require(
            IERC20Token(cUsdTokenAddress).balanceOf(msg.sender) >= amount,
            "Insufficient balance to fund payee."
        );
        // this check was done to make sure the person paying has iven us the necessary allowance to spend that amount of gas fee
        require(
          IERC20Token(cUsdTokenAddress).allowance(msg.sender, address(this)) >= amount,
          "Allowance not set or insufficient balance"
        );
            require(
              IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                payee[_index].owner,
                payee[_index].payeeGasFee
              ),
              "Transfer failed."
            );
            
    }


    /**
        @dev Stores a chat message for a given ID.
        @param id The ID to store the chat message for.
        @param _message The chat message to store.
    */
    function storeChatMessages(uint256 id, string memory _message) public {
         chats[id].push(Chat({owner : msg.sender, message : _message }));
    
    }

    /**
        * @dev Retrieve an array of chat messages for a specific chat ID
        * @param id The ID of the chat messages to retrieve
        * @return An array of chat messages for the specified chat ID
    */
    function getChatsById(uint256 id) public view returns (Chat[] memory) {
        return chats[id];
    }

    
    // function to get the number of payee.
    function getPayeeLength() public view returns (uint) {
        return (payeeLength);
    }    

}
