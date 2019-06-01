pragma solidity ^0.5.0;

    /*
        The EventTickets contract keeps track of the details and ticket sales of one event.
     */

contract EventTickets {

    /*
        Create a public state variable called owner.
        Use the appropriate keyword to create an associated getter function.
        Use the appropriate keyword to allow ether transfers.
     */
    address payable public owner;

    uint   TICKET_PRICE = 100 wei;

    /*
        Create a struct called "Event".
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
    
    Event myEvent;

    //uint ticketsCountForSale;

    /*
        Define 3 logging events.
        LogBuyTickets should provide information about the purchaser and the number of tickets purchased.
        LogGetRefund should provide information about the refund requester and the number of tickets refunded.
        LogEndSale should provide infromation about the contract owner and the balance transferred to them.
    */
    event LogBuyTickets(address indexed _buyer, uint _ticketsCount);
    event LogGetRefund(address indexed _buyer, uint _ticketsCount);
    event LogEndSale(address indexed _owner, uint _totalAmount);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner() { 
        require(msg.sender == owner, "Not authorized"); 
        _; 
    }    
     
    /*
        Define a constructor.
        The constructor takes 3 arguments, the description, the URL and the number of tickets for sale.
        Set the owner to the creator of the contract.
        Set the appropriate myEvent details.
    */
    constructor(string memory _description, string memory _website, uint _totalTicketsForSale) public {
        owner = msg.sender;
        myEvent.description = _description;
        myEvent.website = _website;
        myEvent.totalTickets = _totalTicketsForSale;
        myEvent.sales = 0;
        myEvent.isOpen = true;
    }

    /*
        Define a funciton called readEvent() that returns the event details.
        This function does not modify state, add the appropriate keyword.
        The returned details should be called description, website, uint totalTickets, uint sales, bool isOpen in that order.
    */
    function readEvent() public view returns (string memory description, string memory website, uint totalTickets, uint sales, bool isOpen) {
        return (myEvent.description, myEvent.website, myEvent.totalTickets, myEvent.sales, myEvent.isOpen);
    }

    /*
        Define a function called getBuyerTicketCount().
        This function takes 1 argument, an address and
        returns the number of tickets that address has purchased.
    */
    function getBuyerTicketCount(address _buyer) public view returns (uint) {
        require(_buyer != address(0), "Invalid buyer address");
        return myEvent.buyers[_buyer];
    }


    /*
        Define a function called buyTickets().
        This function allows someone to purchase tickets for the event.
        This function takes one argument, the number of tickets to be purchased.
        This function can accept Ether.
        Be sure to check:
            - That the event isOpen
            - That the transaction value is sufficient for the number of tickets purchased
            - That there are enough tickets in stock
        Then:
            - add the appropriate number of tickets to the purchasers count
            - account for the purchase in the remaining number of available tickets
            - refund any surplus value sent with the transaction
            - emit the appropriate event
    */
    function buyTickets(uint _ticketsCount) public payable {
        require(myEvent.isOpen == true, "Event is closed");
        require(_ticketsCount <= (myEvent.totalTickets-myEvent.sales), "Not enought tickets for sale");
        uint _totalPrice = mul(_ticketsCount, TICKET_PRICE);
        require(msg.value >= _totalPrice, "No bagain");

        myEvent.buyers[msg.sender] += _ticketsCount;
        myEvent.sales += _ticketsCount;
        // Refund if has paid more than expected
        uint _amountToRefund = msg.value - _totalPrice;
        if (_amountToRefund > 0) {
          msg.sender.transfer(_amountToRefund);
        }

        emit LogBuyTickets(msg.sender, _ticketsCount);
    }


    /*
        Define a function called getRefund().
        This function allows someone to get a refund for tickets for the account they purchased from.
        TODO:
            - Check that the requester has purchased tickets.
            - Make sure the refunded tickets go back into the pool of avialable tickets.
            - Transfer the appropriate amount to the refund requester.
            - Emit the appropriate event.
    */
    function getRefund() public payable {
        require(myEvent.isOpen, "Event is closed");
        require(myEvent.buyers[msg.sender] > 0, "No tickets found");
        
        uint _ticketsRefunded = myEvent.buyers[msg.sender];
        uint _amountRefunded = mul(_ticketsRefunded, TICKET_PRICE);
        msg.sender.transfer(_amountRefunded);
        myEvent.buyers[msg.sender] = 0;
        myEvent.sales -= _ticketsRefunded;
        
        emit LogGetRefund(msg.sender, _ticketsRefunded);
    }


    /*
        Define a function called endSale().
        This function will close the ticket sales.
        This function can only be called by the contract owner.
        TODO:
            - close the event
            - transfer the contract balance to the owner
            - emit the appropriate event
    */
    function endSale() public onlyOwner {
        require(myEvent.isOpen == true, "Event is already closed");
        myEvent.isOpen = false;
        uint _total = mul(TICKET_PRICE, myEvent.sales);
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
