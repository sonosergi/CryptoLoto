// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Bitconaire is VRFConsumerBase {
    address payable[] public players;
    address public owner;
    uint8[7] public randomNumbers;
    mapping(address => uint8[7]) public bets;
    mapping(address => bool) public hasClaimedPrize;

    VRFCoordinatorV2Interface private vrfCoordinator;
    bytes32 internal keyHash;
    uint256 internal fee;

    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        owner = msg.sender;
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        fee = _fee;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function registerBet(uint8[7] memory numbers) public payable {
        require(numbers.length == 7, "You must choose exactly 7 numbers");
        require(msg.value > 0, "You must send a bet amount");

        for (uint8 i = 0; i < 7; i++) {
            require(numbers[i] >= 0 && numbers[i] <= 69, "Numbers must be between 0 and 69");
        }

        bets[msg.sender] = numbers;
        players.push(payable(msg.sender));
    }

    function generateRandomNumbers() public onlyOwner {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK balance");
        requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(msg.sender == address(vrfCoordinator), "Fulfillment only allowed from Coordinator");
        randomNumbers = [
            uint8(randomness % 70),
            uint8((randomness >> 8) % 70),
            uint8((randomness >> 16) % 70),
            uint8((randomness >> 24) % 70),
            uint8((randomness >> 32) % 70),
            uint8((randomness >> 40) % 70),
            uint8((randomness >> 48) % 70)
        ];
    }

    function calculateWinners() public onlyOwner {
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, "No balance to distribute");

        // Calculate prize amounts
        uint256 totalPrize = (totalBalance * 81) / 100;
        uint256 adminFee = (totalBalance * 13) / 100;
        uint256 reserveAmount = (totalBalance * 6) / 100;

        // Calculate prize distribution for each category
        uint256 botePrize = (totalPrize * 34) / 100;
        uint256 secondPrize6 = (totalPrize * 21) / 100;
        uint256 thirdPrize5 = (totalPrize * 13) / 100;
        uint256 fourthPrize4 = (totalPrize * 8) / 100;
        uint256 fifthPrize3 = (totalPrize * 5) / 100;

        // Identify winners and distribute prizes
        address[] memory winners7;
        address[] memory winners6;
        address[] memory winners5;
        address[] memory winners4;
        address[] memory winners3;

        for (uint256 i = 0; i < players.length; i++) {
            uint8[7] memory playerNumbers = bets[players[i]];
            uint8 matches = countMatches(playerNumbers, randomNumbers);

            if (matches == 7) {
                winners7 = appendToArray(winners7, players[i]);
            } else if (matches == 6) {
                winners6 = appendToArray(winners6, players[i]);
            } else if (matches == 5) {
                winners5 = appendToArray(winners5, players[i]);
            } else if (matches == 4) {
                winners4 = appendToArray(winners4, players[i]);
            } else if (matches == 3) {
                winners3 = appendToArray(winners3, players[i]);
            }
        }
 
    }

    function countMatches(uint8[7] memory numbers1, uint8[7] memory numbers2) internal pure returns (uint8) {
        uint8 matches = 0;
        for (uint8 i = 0; i < 7; i++) {
            if (numbers1[i] == numbers2[i]) {
                matches++;
            }
        }
        return matches;
    }

    function appendToArray(address[] memory arr, address item) internal pure returns (address[] memory) {
        address[] memory newArr = new address[](arr.length + 1);
        for (uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = item;
        return newArr;
    }

}
