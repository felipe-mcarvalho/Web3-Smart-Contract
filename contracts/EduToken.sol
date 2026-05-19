// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
    Token fungivel do protocolo.
    Ele sera usado para:
    - recompensas
    - staking
    - peso de voto na governanca
*/
contract EduToken is ERC20, Ownable {
    event TokensMinted(address indexed to, uint256 amount);

    constructor(uint256 initialSupply) ERC20("EduStake Token", "EDU") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid recipient.");
        require(amount > 0, "Amount must be greater than zero.");

        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
}
