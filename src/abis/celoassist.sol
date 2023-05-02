// SPDX-License-Identifier: MIT
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
     
    // Creating a constructor for the cUSD address
    constructor(address _cUsdTokenAddress) {
    cUsdTokenAddress = _cUsdTokenAddress;
    }
    
    // Struct to create payee details.
    struct PayeeDetails {
        address payable  owner;
        string payeeFullName;
        string payeeDescription;
        string networkType;
        uint payeeGasFee;   
    }

    // Struct to create chats
    struct Chat{
        address owner;
        string  message;
    }

    // mapping to store payee details
    mapping (uint => PayeeDetails) internal payee;

    // mapping to store chats
    mapping(uint => Chat[]) internal chats;


    // Function to create a payee.
    function createPayee(string memory _payeeFullName, string memory _payeeDescription, string memory _networkType, uint _payeeGasFee   ) public {
          require(bytes(_payeeFullName).length > 0, "field cannot be empty"); 
    require(bytes(_payeeDescription).length > 0, "field cannot be empty");
    require(_payeeGasFee > 0, "fee be greater than 0");
       
        payee[payeeLength] = PayeeDetails({owner : payable(msg.sender), payeeFullName : _payeeFullName,
        payeeDescription : _payeeDescription, networkType : _networkType,
        payeeGasFee :  _payeeGasFee   });
        payeeLength++;
}


    // Function to get a payee details through its id.
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

    // function for a payee to delete his / her request 
    function deletePayeeRequest(uint id) public {
        require(msg.sender == payee[id].owner, "Please ensure you are the owner this request");
         
         // Shift remaining payees down in the mapping
        for (uint i = id; i < payeeLength - 1; i++) {
            payee[i] = payee[i+1];
        }

        // Delete the last element in the mapping
        delete payee[payeeLength - 1];
        payeeLength--;
    }

        // function to fund a payee 
        function fundPayee(uint _index) public payable  {
        require(
           IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            payee[_index].owner,
            payee[_index].payeeGasFee
          ),
          "Transfer failed."
        );
        
    }


    // Function to store chat messages
    function storeChatMessages(uint256 id, string memory _message) public {
         chats[id].push(Chat({owner : msg.sender, message : _message }));
    
    }

    //function to get chats associate with a payee by id
    function getChatsById(uint256 id) public view returns (Chat[] memory) {
        return chats[id];
    }


    // function to get the number of payee.
    function getPayeeLength() public view returns (uint) {
        return (payeeLength);
    }    

}