//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.17;
pragma abicoder v2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Arbitrageur is Ownable {

    event Withdrawn(address indexed to, uint256 indexed value);
    event SwapperUpdated(address indexed to);
    event QuoterUpdated(address indexed to);

    // address payable private bank;
    // Borrower private borrower;
    Swapper private swapper;
    Quoter private quoter;

    constructor(address _swapper, address _quoter) {
        // bank = payable(_bank);
        swapper = Swapper(_swapper);
        quoter = Quoter(_quoter);
    }

    function setSwapper(address _swapper) external onlyOwner {
        swapper = Swapper(_swapper);
        emit SwapperUpdated(_swapper);
    }

    function setQuoter(address _quoter) external onlyOwner {
        quoter = Quoter(_quoter);
        emit QuoterUpdated(_quoter);
    }

    receive() payable external {}
    
    function arbitrage(  
        address pool0,
        address pool1,
        bool P0V3,
        bool P1V3,
        bool zeroToOne,       
        uint256 input,
        uint256 outP0,
        uint256 outP1
    ) external onlyOwner {
        
        (address lowerPool, bool lowerV3) = outP0 < outP1 
        ? (pool0, P0V3) 
        : (pool1, P1V3);
        (address higherPool, bool higherV3) = outP0 < outP1 
        ? (pool1, P1V3) 
        : (pool0, P0V3);

        uint256 quoteDebt = quoter.quoteInput(
            higherPool,
            !zeroToOne, 
            input
        );

        uint256 balanceBefore = (zeroToOne) 
        ? IERC20(IUniswapPool(lowerPool).token0()).balanceOf(address(this))
        : IERC20(IUniswapPool(lowerPool).token1()).balanceOf(address(this));
        
        swapper.swap(
            abi.encode(Swapper.SwapCycle(
             {
                exec: Swapper.SwapParams({
                    receiver: address(this),
                    pool: lowerPool,
                    zeroForOne: zeroToOne,
                    V3: lowerV3,
                    amount: input
                }),
                next: Swapper.SwapParams({
                    receiver: address(this),
                    pool: higherPool,
                    zeroForOne: !zeroToOne,
                    V3: higherV3,
                    amount: quoteDebt
                })
             }
            ))
        );

        uint256 balanceAfter = (zeroToOne) 
        ? IERC20(IUniswapPool(lowerPool).token0()).balanceOf(address(this))
        : IERC20(IUniswapPool(lowerPool).token1()).balanceOf(address(this));
        
        require(balanceAfter > balanceBefore, "Losing money");
        
        // borrower.borrow(abi.encodePacked(bank, _pool0.token0(), _pool0.token1(), _pool0.fee(), _amount0, _amount1));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient funds");
        payable(owner()).transfer(balance);
        emit Withdrawn(owner(), balance);
    }
    
    function withdrawToken(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "Insufficient funds");
        IERC20(token).transfer(owner(), balance);
        emit Withdrawn(owner(), balance);
    }

}

interface IUniswapPool {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface Quoter {
    function quoteOutput(
        address pool, 
        bool zeroToOne, 
        uint256 amountIn
    ) external view returns (uint256 amount);

    function quoteInput(
        address pool, 
        bool zeroToOne, 
        uint256 amountOut
    ) external view returns (uint256 amount);
}

interface Swapper {
    struct SwapParams {
        address receiver;
        address pool;
        bool zeroForOne;
        bool V3;
        uint256 amount;
    }

    struct SwapCycle {
        SwapParams exec;
        SwapParams next;
    }

    function swap(bytes calldata data) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
