pragma solidity ^0.4.24;

import "./Ownable.sol";
import "./Safemath.sol";

contract LuckyNeighbor is Ownable {
    using SafeMath for uint256;
    string public game_name = "LuckyNeighbor";
    uint  constant FIX_BET = 10 ;
    uint  public   luckyPool = 0;
    uint  public   game_number = 1;
    uint  public   randSeed = 0; 
    uint  public   fee = 0; //reward owner

    event BetLog(address user_addresss, uint256 value, uint256 player_number, uint256 game_number, string game_name);
    event AwardLog(address user_addresss, uint256 value, uint256 game_number, string game_name);
 	event BonusLog(address dev_address, uint256 value, uint256 game_number, string game_name);
    event Prize(uint gamenumber);
    
    mapping(uint => address[]) lotteryInfo;
    mapping(uint => uint)      the luckyNumber;
    

    // set the game's name
 	function setGameName(string _name) public onlyOwner {
 		game_name = _name;
 	}

 	// set the game's number
 	function setGameNumber(uint256 _number) public onlyOwner {
 		game_number = _number;
 	}

 	function increaseGameNumber() public {
 		game_number = game_number.add(1);
 	}

    //bet
    function bet(uint mygame_number)public payable {
        require(mygame_number == game_number); //only can bet this unit
        require(msg.value == FIX_BET); 
        require(lotteryInfo[game_number].length < 36); // this unit player must less than 36
        
        uint256  myNum = lotteryInfo[game_number].push(msg.sender); // add playerinfo
        luckyPool = luckyPool.add(msg.value); // luckypool add value
        randSeed = randSeed.add(uint256(msg.sender));
        emit    BetLog(msg.sender, msg.value, myNum, game_number, game_name);

        if (lotteryInfo[game_number].length == 36){
            award();
            emit Prize(luckyNumber[game_number]);
            randSeed = 0;
            game_number.add(1);
        }
    }

    function  award() private {
        //double verify check
        require(lotteryInfo[game_number].length == 36);
        
        //aquire random number
        uint256 random = uint256(keccak256(abi.encodePacked(now, randSeed)))%36;
        luckyNumber[game_number] = random.add(1);
        
        //transfer to winners
        transfertoPlayer(random);
 
    }

    function transfertoPlayer(uint num)private{
        uint perAward = luckyPool.div(36);
        uint i = num + 36;
        // tranfer to winner;
        lotteryInfo[game_number][num].transfer(perAward.mul(6));
        // tranfer to palyer;
        for (uint j = 1; j < 5; j++){
            lotteryInfo[game_number][i.add(j)%36].transfer(perAward.mul(6 - j));
            emit  AwardLog(lotteryInfo[game_number][i.add(j)%35], perAward.mul(6 - j), game_number, game_name);
            lotteryInfo[game_number][i.sub(j)%36].transfer(perAward.mul(6 - j));
            emit  AwardLog(lotteryInfo[game_number][i.sub(j)%35], perAward.mul(6 - j), game_number, game_name);
        }    
            // owner award add perAward*2
        fee = fee.add(perAward.mul(2));
    }
        

    
    // check the lotteryinfo 
    function checkInfo(uint id)public view returns(address[] lottery_address, uint lucky_number){
        
        lottery_address = lotteryInfo[id];
        lucky_number = luckyNumber[id];
        
        return (lottery_address,lucky_number);
    }

    function devBonus(uint256 value) public onlyOwner {
        require(value <= fee);
 		owner.transfer(value);
        fee = fee.sub(value);
 		emit BonusLog(owner, value, game_number, game_name);
 	}
     function () public payable {}
}
