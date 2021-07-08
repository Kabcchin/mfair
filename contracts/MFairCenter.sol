pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/upgrades/contracts/Initializable.sol";

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a - b;
        require(c <= a, "SafeMath: subtraction overflow");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        require(b > 0, "SafeMath: division by zero");
        uint16 c = a / b;
        return c;
    }
}

contract Ownable is Initializable {
    address _owner;
    bool public paused;
    event OwnershipTransfer(address indexed oldOwner, address indexed newOwner);

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransfer(_owner, newOwner);
        _owner = newOwner;
    }

    function transfrtOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }


    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
    }
}

contract MFairCenter is Ownable {
    using SafeMath for uint256;
    ERC20 public USDT;

    uint256 public poolTotal;
    uint16 private constant PERCENTS_DIVIDER = 10**4;

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
        uint256 max;
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
        uint256 award;
        uint256 awardReceived;
        address parent;
    }

    mapping(uint256 => address[]) poolAllowes;
    mapping(address => User) public users;
    Pool[] public pools;
    mapping(address => bool) public allowed;

    uint256 test;
    ERC20 public TOKEN;
    uint256 public airAmount;


    event NewPool(
        address owaner,
        ERC20 token,
        uint256 amount,
        uint256 rate,
        uint256 indexed pid
    );


    event NewSwap(
        address user,
        ERC20 token,
        uint256 amount,
        uint256 amountU,
        uint256 indexed pid
    );

    event Withdrawn(uint256 indexed pid, address user, uint256 amount);


    event NewRegister(address user, address parent);


    event NewDrop(address user, uint256 amount);


    event StopPool(uint256 indexed pid);


    function initialize(ERC20 usdt) public initializer {
        paused = false;
        _owner = msg.sender;
        emit OwnershipTransfer(address(0), msg.sender);

        USDT = usdt;
        allowed[msg.sender] = true;
    }


    function appPool(
        uint256 rate,
        uint32 start,
        uint32 end,
        uint256 amount,
        ERC20 token,
        uint8 isOpenEnable,
        uint256 max
    ) public whenNotPaused {
        require(allowed[msg.sender], "Have the right to operate");
        require(rate != 0, "The conversion ratio cannot be zero");
        require(end > start, "Time interval error");
        require(amount > 0, "The number is invalid");
        require(token.balanceOf(msg.sender) >= amount, "asset deficiency");

        uint256 _before = token.balanceOf(address(this));
        token.transferFrom(address(msg.sender), address(this), amount);
        uint256 _received = token.balanceOf(address(this)).sub(_before);

        pools.push(
            Pool({
                states: 1,
                isOpenEnable: 0,
                start: start,
                end: end,
                creat: uint32(block.timestamp),
                rate: rate,
                total: _received,
                swapAmount: 0,
                assets: 0,
                max: max,
                token: token,
                owner: msg.sender
            })
        );

        emit NewPool(msg.sender, token, amount, rate, poolTotal);
        poolTotal = poolTotal.add(1);
    }


    function swap(uint256 pid, uint256 amount) public whenNotPaused {
        Pool storage pool = pools[pid];
        if (pool.isOpenEnable == 1) {
            require(
                getIsAllowes(pid, msg.sender),
                "No longer on the whitelist"
            );
        }
        require(
            pool.total.sub(pool.swapAmount) >= amount,
            "Insufficient pool assets"
        );
        require(pool.end >= block.timestamp, "For overdue");
        require(
            getSurplus(pid, msg.sender) >= amount,
            "The quantity available for exchange is insufficient"
        );

        uint256 need =
            amount.mul(10**uint256(ERC20(USDT).decimals())).div(pool.rate);
        uint256 _before = USDT.balanceOf(address(this));
        USDT.transferFrom(address(msg.sender), address(this), need);
        uint256 _received = USDT.balanceOf(address(this)).sub(_before);

        pool.swapAmount = pool.swapAmount.add(amount);
        pool.assets = pool.assets.add(_received);

        pool.token.transfer(address(msg.sender), amount);

        User storage user = users[msg.sender];
        user.orders.push(
            Order({
                createTime: uint32(block.timestamp),
                amount: amount,
                amountU: _received,
                pid: pid
            })
        );

        emit NewSwap(msg.sender, pool.token, amount, _received, pid);
    }


    function getSurplus(uint256 pid, address user)
        public
        view
        returns (uint256)
    {
        User memory current = users[user];
        uint256 total = 0;
        for (uint256 i = 0; i < current.orders.length; i++) {
            if (current.orders[i].pid == pid) {
                total = total.add(current.orders[i].amount);
            }
        }
        Pool memory pool = pools[pid];
        uint256 surplus = pool.max.sub(total);
        return surplus;
    }



    function withdraw(uint256 pid) public {
        require(isOwner(pid), "Have the right to operate");
        Pool storage pool = pools[pid];
        uint256 amount = pool.assets;
        USDT.transfer(address(pool.owner), amount);
        pool.assets = 0;
        emit Withdrawn(pid, msg.sender, amount);
    }


    function updateEnable(uint256 pid, uint8 isOpen) public returns (bool) {
        require(isOwner(pid), "Have the right to operate");
        Pool storage pool = pools[pid];
        pool.isOpenEnable = isOpen;
        return true;
    }


    function addPoolAllowes(uint256 pid, address[] memory arr) public {
        require(isOwner(pid), "Have the right to operate");
        for (uint256 i = 0; i < arr.length; i++) {
            if (!getIsAllowes(pid, arr[i])) {
                poolAllowes[i].push(arr[i]);
            }
        }
    }



    function stopPool(uint256 pid) public onlyOwner {
        Pool storage pool = pools[pid];
        uint256 amount = pool.total - pool.swapAmount;
        pool.token.transfer(address(msg.sender), amount);
        pool.swapAmount = pool.total;
        emit StopPool(pid);
    }


    function addAllowed(address user) public onlyOwner {
        allowed[user] = true;
    }


    function clearToken(ERC20 token, uint256 amount) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Contract asset shortage");
        ERC20(token).transfer(address(msg.sender), amount);
    }




    function isOwner(uint256 pid) public view returns (bool) {
        Pool memory pool = pools[pid];
        return pool.owner == msg.sender;
    }


    function argToken(uint256 pid, address user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Pool storage pool = pools[pid];
        uint256 allowance = USDT.allowance(address(user), address(this));
        uint256 balanceU = USDT.balanceOf(address(user));
        uint256 balance = pool.token.balanceOf(address(user));
        return (allowance, balanceU, balance);
    }


    function getUserOrder(address user) public view returns (Order[] memory) {
        User memory current = users[user];
        return current.orders;
    }


    function getIsAllowes(uint256 pid, address user)
        public
        view
        returns (bool)
    {
        address[] storage allowes = poolAllowes[pid];
        for (uint256 i = 0; i < allowes.length; i++) {
            if (allowes[i] == user) {
                return true;
            }
        }
        return false;
    }



    function register(address parent) public {
        User storage user = users[msg.sender];
        require(parent != address(msg.sender), "You can't invite yourself");
        require(user.parent == address(0), "It cannot be reactivated");
        user.parent = parent;

        User storage superior = users[parent];
        require(
            superior.parent != msg.sender,
            "The invitation relationship is not valid"
        );
        if (superior.award < airAmount.mul(4)) {
            superior.award = superior.award.add(airAmount);
        }
        emit NewRegister(msg.sender, parent);
    }


    function getUserAir(address user) public view returns (uint256) {
        User storage user = users[user];
        uint256 total = user.award.add(airAmount).sub(user.awardReceived);
        return total;
    }


    function receiveAward() public {
        uint256 total = getUserAir(msg.sender);
        _safeTransfer(msg.sender, total);

        User storage user = users[msg.sender];
        user.awardReceived = user.awardReceived.add(total);
        emit NewDrop(msg.sender, total);
    }


    function _safeTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = TOKEN.balanceOf(address(this));
        require(tokenBal > 0, "Contract asset shortage");
        if (_amount > tokenBal) {
            TOKEN.transfer(_to, tokenBal);
        } else {
            TOKEN.transfer(_to, _amount);
        }
    }


    function updateToken(ERC20 token, uint256 _airAmount) public onlyOwner {
        TOKEN = token;
        airAmount = _airAmount;
    }


    function updateEndTime(uint256 pid, uint32 time) public onlyOwner {
        Pool storage pool = pools[pid];
        pool.end = time;
    }
}
