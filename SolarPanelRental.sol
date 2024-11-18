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
        uint256 siteId; // The site where the panel is located
    }

    // Define the site structure (Messukeskus Solar Power Plant)
    struct Site {
        uint256 siteId;
        string siteName;
        string location;
        uint256 totalPanels; // Total panels at this site
        uint256 availablePanels; // Panels available for rent at this site
    }

    // Define owner (company that owns the panels)
    address public owner;

    // Mappings to store panels and sites
    mapping(uint256 => Panel) public panels; // Mapping for panels by panelId
    mapping(uint256 => Site) public sites; // Mapping for sites by siteId
    mapping(address => uint256) public renterPayments; // Mapping to track payments per renter

    // Event when a panel is rented
    event PanelRented(address indexed renter, uint256 panelId, uint256 siteId, uint256 startDate, uint256 endDate);

    // Event when a panel is returned
    event PanelReturned(address indexed renter, uint256 panelId, uint256 siteId, uint256 returnDate);

    // Constructor sets the contract owner
    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict access to only the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    // Function to add a new site (e.g., Messukeskus Solar Power Plant)
    function addSite(uint256 _siteId, string memory _siteName, string memory _location, uint256 _totalPanels) public onlyOwner {
        require(sites[_siteId].siteId == 0, "Site already exists.");
        sites[_siteId] = Site({
            siteId: _siteId,
            siteName: _siteName,
            location: _location,
            totalPanels: _totalPanels,
            availablePanels: _totalPanels
        });
    }

    // Function to add a new panel to a specific site
    function addPanel(uint256 _panelId, uint256 _siteId, uint256 _rentalPrice) public onlyOwner {
        require(sites[_siteId].siteId != 0, "Site does not exist."); // Ensure the site exists
        require(!panels[_panelId].isAvailable, "Panel already exists.");

        panels[_panelId] = Panel({
            panelId: _panelId,
            isAvailable: true,
            rentalPrice: _rentalPrice,
            currentRenter: address(0),
            rentalStart: 0,
            rentalEnd: 0,
            siteId: _siteId
        });

        // Update the site's available panels
        sites[_siteId].availablePanels++;
    }

    // Function to rent a panel from a specific site
    function rentPanel(uint256 _panelId, uint256 _siteId, uint256 _rentalDuration) public payable {
        Panel storage panel = panels[_panelId];
        require(panel.siteId == _siteId, "Panel is not located at the specified site.");
        require(panel.isAvailable, "Panel is not available for rent.");
        require(msg.value >= panel.rentalPrice * _rentalDuration, "Insufficient payment.");

        // Mark panel as rented
        panel.isAvailable = false;
        panel.currentRenter = msg.sender;
        panel.rentalStart = block.timestamp;
        panel.rentalEnd = block.timestamp + (_rentalDuration * 30 days); // Rental duration in days

        // Decrease the available panels at the site
        Site storage site = sites[panel.siteId];
        site.availablePanels--;

        // Transfer rental fee to the owner
        payable(owner).transfer(msg.value);

        emit PanelRented(msg.sender, _panelId, panel.siteId, panel.rentalStart, panel.rentalEnd);
    }

    // Function to return a rented panel
    function returnPanel(uint256 _panelId, uint256 _siteId) public {
        Panel storage panel = panels[_panelId];
        require(panel.siteId == _siteId, "Panel is not located at the specified site.");
        require(panel.currentRenter == msg.sender, "You are not the renter of this panel.");
        require(panel.rentalEnd <= block.timestamp, "Rental period not yet over.");

        // Mark the panel as available
        panel.isAvailable = true;
        panel.currentRenter = address(0);
        panel.rentalStart = 0;
        panel.rentalEnd = 0;

        // Increase the available panels at the site
        Site storage site = sites[panel.siteId];
        site.availablePanels++;

        emit PanelReturned(msg.sender, _panelId, panel.siteId, block.timestamp);
    }

    // Function to check if a panel is available at a specific site
    function checkAvailability(uint256 _panelId, uint256 _siteId) public view returns (bool) {
        require(sites[_siteId].siteId != 0, "Site does not exist.");
        return panels[_panelId].isAvailable && panels[_panelId].siteId == _siteId;
    }

    // Function to get the rental price of a panel at a specific site
    function getRentalPrice(uint256 _panelId, uint256 _siteId) public view returns (uint256) {
        require(sites[_siteId].siteId != 0, "Site does not exist.");
        return panels[_panelId].rentalPrice;
    }

    // Function to retrieve the current renter of a panel at a specific site
    function getCurrentRenter(uint256 _panelId, uint256 _siteId) public view returns (address) {
        require(sites[_siteId].siteId != 0, "Site does not exist.");
        return panels[_panelId].currentRenter;
    }

    // Function to get the details of a site (location, name, and available panels)
    function getSiteDetails(uint256 _siteId) public view returns (string memory siteName, string memory location, uint256 totalPanels, uint256 availablePanels) {
        require(sites[_siteId].siteId != 0, "Site does not exist.");
        Site storage site = sites[_siteId];
        return (site.siteName, site.location, site.totalPanels, site.availablePanels);
    }

    // Function to get all panels available at a specific site
    function getAvailablePanelsAtSite(uint256 _siteId) public view returns (uint256[] memory) {
        require(sites[_siteId].siteId != 0, "Site does not exist.");
        uint256 totalPanels = sites[_siteId].totalPanels;
        uint256 availableCount = 0;

        // Count the available panels
        for (uint256 i = 0; i < totalPanels; i++) {
            if (panels[i].siteId == _siteId && panels[i].isAvailable) {
                availableCount++;
            }
        }

        uint256[] memory availablePanelIds = new uint256[](availableCount);
        uint256 index = 0;
        for (uint256 i = 0; i < totalPanels; i++) {
            if (panels[i].siteId == _siteId && panels[i].isAvailable) {
                availablePanelIds[index] = panels[i].panelId;
                index++;
            }
        }

        return availablePanelIds;
    }
}
