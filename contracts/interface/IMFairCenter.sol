pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface CenterStruct {
    struct Pool {
        uint8 states;
        uint8 isOpenEnable;
        uint32 start;
        uint32 end;
        uint32 creat;
        uint256 rate;
        uint256 total;
        uint256 swapAmount;
        uint256 assets;
        ERC20 token;
        address owner;
    }
    struct Order {
        uint32 createTime;
        uint256 amount;
        uint256 amountU;
        uint256 pid;
    }

    struct User {
        Order[] orders;
    }
}

interface MFairCenter is CenterStruct {


    function poolTotal() external view returns (uint256);


    function USDT() external view returns (address);


    function pools(uint256 pid) external view returns (Pool memory);


    function isOwner(uint256 pid) external view returns (bool);


    function argToken(uint256 pid, address user)
        external
        returns (
            uint256,
            uint256,
            uint256
        );


    function getUserOrder(address user) external view returns (Order[] memory);


    function getIsAllowes(uint256 pid, address user)
        external
        view
        returns (bool);



    function appPool(
        uint256 rate,
        uint32 start,
        uint32 end,
        uint256 amount,
        ERC20 token,
        uint8 isOpenEnable
    ) external;


    function swap(uint256 pid, uint256 amount) external;


    function withdraw(uint256 pid) external;


    function updateEnable(uint256 pid, uint8 isOpen) external returns (bool);


    function addPoolAllowes(uint256 pid, address[] memory arr) external;


    function getBlock() external view returns (uint256);

    function test() external view returns (uint256);

    function setTest(uint256 value) external;
}
