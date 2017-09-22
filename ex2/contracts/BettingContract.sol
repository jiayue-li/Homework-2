pragma solidity ^0.4.15;

contract BettingContract {
	/* Standard state variables */
	address owner;
	address public gamblerA;
	address public gamblerB;
	address public oracle;
	uint[] outcomes;

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
		uint outcome;
		uint amount;
		bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet) bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetMade(address gambler);
	event BetClosed();

	/* Uh Oh, what are these? */
	modifier OwnerOnly() {
	    require(msg.sender == owner);
	    require(msg.sender != oracle);
	    _;
	}
	modifier OracleOnly() {
	    require (msg.sender == oracle);
	    require (msg.sender != gamblerA);
	    require (msg.sender != gamblerB);
	    _;
	}

	/* Constructor function, where owner and outcomes are set */
	function BettingContract(uint[] _outcomes) {
	    owner = msg.sender;
	    outcomes = _outcomes;
	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
	    oracle = _oracle;
	    return oracle;
	}

	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable returns (bool) {
	    if (gamblerA == 0){
	        gamblerA = msg.sender;
	    }else if ((msg.sender != gamblerA) && (gamblerB == 0)){
	        gamblerB = msg.sender;
	    }else{
	        return false;
	    }
	    Bet storage bet;
	    bet.outcome = _outcome;
	    bet.amount = msg.value;
	    bet.initialized = true;

	    bets[msg.sender] = bet;
	    BetMade(msg.sender);
	    return true;
	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
	    uint betAmountA = bets[gamblerA].amount;
	    uint betAmountB = bets[gamblerB].amount;
	    uint outcomeA = bets[gamblerA].outcome;
	    uint outcomeB = bets[gamblerB].outcome;
	    uint total = betAmountA + betAmountB;

	    if (outcomeA == outcomeB){
	        winnings[gamblerA] = betAmountA;
	        winnings[gamblerB] = betAmountB;
	    }else if(outcomeA == _outcome){
	        winnings[gamblerA] = total;
	    }else if(outcomeB == _outcome){
	        winnings[gamblerB] = total;
	    }else{
	        winnings[oracle] = total;
	    }
	    BetClosed();
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
	    if (withdrawAmount <= winnings[msg.sender]){
	        winnings[msg.sender] -= withdrawAmount;
	        if (!msg.sender.send(withdrawAmount)){
	            winnings[msg.sender] += withdrawAmount;
	        }
	        return winnings[msg.sender];
	    }
	}

	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
	    return outcomes;
	}

	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
	    return winnings[msg.sender];
	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
	    delete(outcomes);
	    delete(bets[0]);
	    delete(bets[1]);
	    delete(gamblerA);
	    delete(gamblerB);
	}

	/* Fallback function */
	function() {
		revert();
	}
}
