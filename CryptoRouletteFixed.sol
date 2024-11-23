// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CryptoRoulette {

    uint256 private secretNumber;
    uint256 public lastPlayed;
    uint256 public constant betPrice = 0.1 ether;
    address public immutable ownerAddr;
    bool public isActive = true;

    struct Game {
        address player;
        uint256 number;
    }
    Game[] public gamesPlayed;

    event GamePlayed(address indexed player, uint256 number, bool won);
    event ContractDisabled(address owner, uint256 balance);

    constructor() {
        ownerAddr = msg.sender;
        shuffle();
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddr, "Only owner can call");
        _;
    }

    modifier contractIsActive() {
        require(isActive, "Contract is disabled");
        _;
    }

    function shuffle() internal {
        secretNumber = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender))) % 20 + 1;
    }

    function play(uint256 number) external payable contractIsActive {
        require(msg.value >= betPrice, "Insufficient bet amount");
        require(number >= 1 && number <= 20, "Invalid number range");

        gamesPlayed.push(Game(msg.sender, number));

        bool isWinner = (number == secretNumber);
        if (isWinner) {
            uint256 prize = address(this).balance;
            payable(msg.sender).transfer(prize);
        }

        emit GamePlayed(msg.sender, number, isWinner);

        shuffle();
        lastPlayed = block.timestamp;
    }

    function disableContract() external onlyOwner {
        require(block.timestamp > lastPlayed + 1 days, "Cannot disable contract before 24 hours of inactivity");

        isActive = false;

        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(ownerAddr).transfer(balance);
        }

        emit ContractDisabled(ownerAddr, balance);
    }

    receive() external payable {}
}
