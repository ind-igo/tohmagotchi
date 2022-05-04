// SPDX-License-Identifier: Unlicense

/*
  (w) (a) (g) (m) (i)
  by dom
*/

pragma solidity ^0.8.0;

contract Tohmagotchi {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Tohmagotchi_NotOwner();
    error Tohmagotchi_Dead();
    error Tohmagotchi_Bored();
    error Tohmagotchi_Unclean();
    error Tohmagotchi_Hungry();
    error Tohmagotchi_Sleepy();
    error Tohmagotchi_Full();
    error Tohmagotchi_Clean();
    error Tohmagotchi_Content();
    error Tohmagotchi_Awake();

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address _owner;
    bool _birthed;

    uint256 lastFeedBlock;
    uint256 lastCleanBlock;
    uint256 lastPlayBlock;
    uint256 lastSleepBlock;

    uint8 internal hunger;
    uint8 internal uncleanliness;
    uint8 internal boredom;
    uint8 internal sleepiness;

    mapping(address => uint256) public love;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event CaretakerLoved(address indexed caretaker, uint256 indexed amount);

    constructor() {
        _owner = msg.sender;
        lastFeedBlock = block.number;
        lastCleanBlock = block.number;
        lastPlayBlock = block.number;
        lastSleepBlock = block.number;

        hunger = 0;
        uncleanliness = 0;
        boredom = 0;
        sleepiness = 0;
    }

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    function onlyOwner() internal view returns (bool) {
        return msg.sender == _owner;
    }

    /*///////////////////////////////////////////////////////////////
                                CARETAKING
    //////////////////////////////////////////////////////////////*/

    function feed() public {
        if (!getAlive()) revert Tohmagotchi_Dead();
        if (getBoredom() >= 80) revert Tohmagotchi_Bored();
        if (getUncleanliness() >= 80) revert Tohmagotchi_Unclean();
        if (getHunger() == 0) revert Tohmagotchi_Full();

        lastFeedBlock = block.number;

        hunger = 0;
        boredom += 10;
        uncleanliness += 3;

        addLove(msg.sender, 1);
    }

    function clean() public {
        if (!getAlive()) revert Tohmagotchi_Dead();
        if (getUncleanliness() == 0) revert Tohmagotchi_Clean();

        lastCleanBlock = block.number;

        uncleanliness = 0;

        addLove(msg.sender, 1);
    }

    function play() public {
        if (!getAlive()) revert Tohmagotchi_Dead();
        if (getHunger() >= 80) revert Tohmagotchi_Hungry();
        if (getSleepiness() >= 80) revert Tohmagotchi_Sleepy();
        if (getUncleanliness() >= 80) revert Tohmagotchi_Unclean();
        if (getBoredom() == 0) revert Tohmagotchi_Content();

        lastPlayBlock = block.number;

        boredom = 0;
        hunger += 10;
        sleepiness += 10;
        uncleanliness += 5;

        addLove(msg.sender, 1);
    }

    function sleep() public {
        if (!getAlive()) revert Tohmagotchi_Dead();
        if (getUncleanliness() >= 80) revert Tohmagotchi_Unclean();
        if (getSleepiness() == 0) revert Tohmagotchi_Awake();

        lastSleepBlock = block.number;

        sleepiness = 0;
        uncleanliness += 5;

        addLove(msg.sender, 1);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function addLove(address caretaker, uint256 amount) internal {
        love[caretaker] += amount;
        emit CaretakerLoved(caretaker, amount);
    }

    /*///////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    function getStatus() public view returns (string memory) {
        uint256 mostNeeded = 0;

        string[4] memory goodStatus = [
            "gm",
            "im feeling great",
            "all good",
            "i love u"
        ];

        string memory status = goodStatus[block.number % 4];

        uint256 _hunger = getHunger();
        uint256 _uncleanliness = getUncleanliness();
        uint256 _boredom = getBoredom();
        uint256 _sleepiness = getSleepiness();

        if (getAlive() == false) {
            return "no longer with us";
        }

        if (_hunger > 50 && _hunger > mostNeeded) {
            mostNeeded = _hunger;
            status = "im hungry";
        }

        if (_uncleanliness > 50 && _uncleanliness > mostNeeded) {
            mostNeeded = _uncleanliness;
            status = "i need a bath";
        }

        if (_boredom > 50 && _boredom > mostNeeded) {
            mostNeeded = _boredom;
            status = "im bored";
        }

        if (_sleepiness > 50 && _sleepiness > mostNeeded) {
            mostNeeded = _sleepiness;
            status = "im sleepy";
        }

        return status;
    }

    function getAlive() public view returns (bool) {
        return
            getHunger() < 101 &&
            getUncleanliness() < 101 &&
            getBoredom() < 101 &&
            getSleepiness() < 101;
    }

    function getHunger() public view returns (uint256) {
        return hunger + ((block.number - lastFeedBlock) / 50);
    }

    function getUncleanliness() public view returns (uint256) {
        return uncleanliness + ((block.number - lastCleanBlock) / 50);
    }

    function getBoredom() public view returns (uint256) {
        return boredom + ((block.number - lastPlayBlock) / 50);
    }

    function getSleepiness() public view returns (uint256) {
        return sleepiness + ((block.number - lastSleepBlock) / 50);
    }
}
