pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;

    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;
    
    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) public events;
    

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner() { 
        require(msg.sender == owner, "Not authorized"); 
        _; 
    }  

    constructor() public {
        owner = msg.sender;
    }


    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _website, uint _totalTicketsForSale) public onlyOwner returns(uint _id) {
        _id = idGenerator;
        idGenerator += 1;
        events[_id] = Event({
            description: _description, 
            website: _website, 
            totalTickets: _totalTicketsForSale, 
            sales: 0,
            isOpen: true
            });
        
        emit LogEventAdded(_description, _website, _totalTicketsForSale, _id);
    }
    

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */
    function readEvent(uint _id) public view returns (string memory description, string memory website, uint totalTickets, uint sales, bool isOpen) {
        Event storage _event = events[_id];
        return (_event.description, _event.website, _event.totalTickets, _event.sales, _event.isOpen);
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */

    function buyTickets(uint _eventId, uint _ticketsCount) public payable {
        Event storage _event = events[_eventId];
        require(_event.isOpen == true, "Event is closed");
        require(_ticketsCount <= (_event.totalTickets-_event.sales), "Not enought tickets for sale");
        uint _totalPrice = mul(_ticketsCount, PRICE_TICKET);
        require(msg.value >= _totalPrice, "No bagain");

        _event.buyers[msg.sender] += _ticketsCount;
        _event.sales += _ticketsCount;
        // Refund if has paied more than expected
        uint _amountToRefund = msg.value - _totalPrice;
        if (_amountToRefund > 0) {
          msg.sender.transfer(_amountToRefund);
        }

        emit LogBuyTickets(msg.sender, _eventId, _ticketsCount);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _eventId) public payable {
        Event storage _event = events[_eventId];
        require(_event.isOpen == true, "Event is closed");
        require(_event.buyers[msg.sender] > 0, "No tickets found for this event");
        
        uint _ticketsRefunded = _event.buyers[msg.sender];
        uint _amountRefunded = mul(_ticketsRefunded, PRICE_TICKET);
        msg.sender.transfer(_amountRefunded);
        _event.buyers[msg.sender] = 0;
        _event.sales -= _ticketsRefunded;
        
        emit LogGetRefund(msg.sender, _eventId, _ticketsRefunded);
    }
    
    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _eventId) public view returns(uint) {
        return events[_eventId].buyers[msg.sender];
    }


    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventId) public onlyOwner {
        Event storage _event = events[_eventId];
        require(_event.isOpen == true, "Event is closed");
        
        _event.isOpen = false;
        uint _total = mul(PRICE_TICKET, _event.sales);
        if (_total > 0) {
            owner.transfer(_total);
        }

        emit LogEndSale(owner, _total);
    }


    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

}
