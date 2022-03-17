// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyBlockgamesToken is ERC20 {
    constructor() ERC20("MyBlockgamesToken", "MBT") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
    function buyToken(address receiver) public payable {
        // since 1 ether = 1000 MBT, 1 MBT = (1  / 10000) = 0.001 ether
        uint priceOf_1MBT = 0.001 ether;
        require(msg.value > priceOf_1MBT, "Cost of buying MBT is 1000 MBT per ETH");
        uint numberOf_MBT = msg.value / priceOf_1MBT;
        _mint(receiver, numberOf_MBT);
    }
}
