// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0; 

import "./Ownable.sol";

contract Constants {
    uint256 public tradeFlag = 1;
    uint256 public basicFlag = 0;
    uint256 public dividendFlag = 1;
}

contract GasContract is Ownable, Constants {
    uint256 public totalSupply = 0;
    uint256 public paymentCounter = 0;
    mapping(address => uint256) public balances;
    uint256 public tradePercent = 12;
    address public contractOwner;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    address[5] public administrators;
    bool public isReady = false;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    PaymentType constant defaultPayment = PaymentType.Unknown;

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName;
        address recipient;
        address admin;
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }
    
    struct ImportantStruct {
        uint256 amount;
        uint256 valueA;
        uint256 bigValue;
        uint256 valueB;
        bool paymentStatus;
        address sender;
    }
    mapping(address => ImportantStruct) public whiteListStruct;
    mapping(uint256 => Payment) public paymentMap;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event PaymentUpdated(address admin, uint256 ID, uint256 amount, string recipient);
    event Transfer(address recipient, uint256 amount);

    modifier onlyAdminOrOwner() {
        require(checkForAdmin(msg.sender) || msg.sender == contractOwner, "Gas Contract: Caller is not admin or owner");
        _;
    }

    modifier checkIfWhiteListed(address sender) {
        require(msg.sender == sender, "Gas Contract: Caller is not the sender");
        require(whitelist[sender] > 0, "Gas Contract: Sender is not whitelisted");
        require(whitelist[sender] < 4, "Gas Contract: Incorrect whitelist tier");
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                } else {
                    balances[_admins[ii]] = 0;
                }
            }
        }
    }

    function getPaymentHistory() public payable returns (History[] memory paymentHistory_) {
        return paymentHistory;
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                return true;
            }
        }
        return false;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function addHistory(address _updateAddress, bool _tradeMode) public returns (bool status_, bool tradeMode_) {
        History memory history;
        history.blockNumber = block.number;
        history.lastUpdate = block.timestamp;
        history.updatedBy = _updateAddress;
        paymentHistory.push(history);
        return (true, _tradeMode);
    }

    function getPayments(address _user) public view returns (Payment[] memory payments_) {
        require(_user != address(0), "Gas Contract: User address is invalid");
        return payments[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) public returns (bool status_) {
        require(balances[msg.sender] >= _amount, "Gas Contract: Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        uint256 paymentID = ++paymentCounter;
        paymentMap[paymentID] = Payment({
            paymentType: PaymentType.BasicPayment,
            paymentID: paymentID,
            adminUpdated: false,
            recipientName: _name,
            recipient: _recipient,
            admin: address(0),
            amount: _amount
        });
        payments[msg.sender].push(paymentMap[paymentID]);
        return true;
    }

    function updatePayment(address _user, uint256 _ID, uint256 _amount, PaymentType _type) public onlyAdminOrOwner {
        require(_ID > 0, "Gas Contract: Invalid payment ID");
        require(_amount > 0, "Gas Contract: Invalid payment amount");
        require(_user != address(0), "Gas Contract: Invalid administrator address");

        paymentMap[_ID].adminUpdated = true;
        paymentMap[_ID].admin = _user;
        paymentMap[_ID].paymentType = _type;
        paymentMap[_ID].amount = _amount;
        bool tradingMode = getTradingMode();
        addHistory(_user, tradingMode);
        emit PaymentUpdated(msg.sender, _ID, _amount, paymentMap[_ID].recipientName);
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public onlyAdminOrOwner {
        require(_tier < 255, "Gas Contract: Invalid whitelist tier");
        whitelist[_userAddrs] = _tier;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public checkIfWhiteListed(msg.sender) {
        require(balances[msg.sender] >= _amount, "Gas Contract: Insufficient balance");
        require(_amount > 3, "Gas Contract: Invalid transfer amount");
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
    }

    function getPaymentStatus(address sender) public view returns (bool, uint256) {
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
         payable(msg.sender).transfer(msg.value);
    }
}