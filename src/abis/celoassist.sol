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

contract CeloAssist {
    using Strings for uint256;

    uint private payeeLength = 0;
    address private cUsdTokenAddress;

    struct PayeeDetails {
        address payable owner;
        string payeeFullName;
        string payeeDescription;
        string networkType;
        uint payeeGasFee;
    }

    struct Chat {
        address owner;
        string message;
    }

    mapping (uint => PayeeDetails) private payee;
    mapping (uint => Chat[]) private chats;

    constructor(address _cUsdTokenAddress) {
        cUsdTokenAddress = _cUsdTokenAddress;
    }

    function createPayee(string memory _payeeFullName, string memory _payeeDescription, string memory _networkType, uint _payeeGasFee) public {
        require(bytes(_payeeFullName).length > 0, "Full name cannot be empty");
        require(bytes(_payeeDescription).length > 0, "Description cannot be empty");
        require(_payeeGasFee > 0, "Gas fee must be greater than 0");

        payee[payeeLength] = PayeeDetails({
            owner: payable(msg.sender),
            payeeFullName: _payeeFullName,
            payeeDescription: _payeeDescription,
            networkType: _networkType,
            payeeGasFee: _payeeGasFee
        });

        payeeLength++;
    }

    function fetchPayeeById(uint _payeeId) public view returns (
        address,
        string memory,
        string memory,
        string memory,
        uint
    ) {
        return (
            payee[_payeeId].owner,
            payee[_payeeId].payeeFullName, 
            payee[_payeeId].payeeDescription,
            payee[_payeeId].networkType,
            payee[_payeeId].payeeGasFee
        );
    }

    function deletePayeeRequest(uint _payeeId) public {
        require(msg.sender == payee[_payeeId].owner, "You must be the owner of the request");

        for (uint i = _payeeId; i < payeeLength - 1; i++) {
            payee[i] = payee[i+1];
        }

        delete payee[payeeLength - 1];
        payeeLength--;
    }

    function fundPayee(uint _payeeIndex) public payable {
        require(payee[_payeeIndex].owner != address(0), "Payee does not exist");
        require(msg.value == payee[_payeeIndex].payeeGasFee, "Invalid payment amount");

        bool success = IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            payee[_payeeIndex].owner,
            payee[_payeeIndex].payeeGasFee
        );

        require(success, "Token transfer failed");
    }

    function storeChatMessages(uint256 _payeeId, string memory _message) public {
        require(bytes(_message).length > 0, "Message cannot be empty");

        chats[_payeeId].push(Chat({
            owner: msg.sender,
            message: _message
        }));
    }

    function getChatsById(uint256 _payeeId) public view returns (Chat[] memory) {
        return chats[_payeeId];
    }

    function getPayeeLength() public view returns (uint) {
        return payeeLength;
    }
}