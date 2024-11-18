// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SolarPanelRental {
    // Define the panel structure
    struct Panel {
        uint256 panelId;
        bool isAvailable;
        uint256 rentalPrice; // Monthly price for renting
        address currentRenter; // Address of the current renter
        uint256 rentalStart; // Timestamp when the rental starts
        uint256 rentalEnd; // Timestamp when the rental ends
    }

    // Define owner (company that owns the panels)
    address public owner;

    // Mapping to store panels
    mapping(uint256 => Panel) public panels;

    // Mapping for panel renters to track payments
    mapping(address => uint256) public renterPayments;

    // Event when a panel is rented
    event PanelRented(address indexed renter, uint256 panelId, uint256 startDate, uint256 endDate);

    // Event when a panel is returned
    event PanelReturned(address indexed renter, uint256 panelId, uint256 returnDate);

    // Constructor sets the contract owner
    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict access to only the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    // Function to add a new panel to the system
    function addPanel(uint256 _panelId, uint256 _rentalPrice) public onlyOwner {
        require(!panels[_panelId].isAvailable, "Panel already exists.");
        panels[_panelId] = Panel({
            panelId: _panelId,
            isAvailable: true,
            rentalPrice: _rentalPrice,
            currentRenter: address(0),
            rentalStart: 0,
            rentalEnd: 0
        });
    }

    // Function to rent a panel
    function rentPanel(uint256 _panelId, uint256 _rentalDuration) public payable {
        Panel storage panel = panels[_panelId];
        require(panel.isAvailable, "Panel is not available for rent.");
        require(msg.value >= panel.rentalPrice * _rentalDuration, "Insufficient payment.");

        panel.isAvailable = false;
        panel.currentRenter = msg.sender;
        panel.rentalStart = block.timestamp;
        panel.rentalEnd = block.timestamp + (_rentalDuration * 30 days); // Rental duration in days

        // Transfer rental fee to the owner
        payable(owner).transfer(msg.value);

        emit PanelRented(msg.sender, _panelId, panel.rentalStart, panel.rentalEnd);
    }

    // Function to return a rented panel
    function returnPanel(uint256 _panelId) public {
        Panel storage panel = panels[_panelId];
        require(panel.currentRenter == msg.sender, "You are not the renter of this panel.");
        require(panel.rentalEnd <= block.timestamp, "Rental period not yet over.");

        panel.isAvailable = true;
        panel.currentRenter = address(0);
        panel.rentalStart = 0;
        panel.rentalEnd = 0;

        emit PanelReturned(msg.sender, _panelId, block.timestamp);
    }

    // Function to check if a panel is available
    function checkAvailability(uint256 _panelId) public view returns (bool) {
        return panels[_panelId].isAvailable;
    }

    // Function to get the rental price of a panel
    function getRentalPrice(uint256 _panelId) public view returns (uint256) {
        return panels[_panelId].rentalPrice;
    }

    // Function to retrieve the current renter of a panel
    function getCurrentRenter(uint256 _panelId) public view returns (address) {
        return panels[_panelId].currentRenter;
    }
}
