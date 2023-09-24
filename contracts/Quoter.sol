//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.17;
pragma abicoder v2;

contract Quoter {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    function quoteInput(
        address pool, 
        bool zeroToOne, 
        uint256 amountOut
    ) external view returns (uint256 amount) {
        (uint112 reserveIn, uint112 reserveOut) = _getReserves(
            IUniswapV2Pair(pool), 
            zeroToOne
        );

        amount = _getAmountIn(
            amountOut,
            reserveIn,
            reserveOut
        );
    }

    function quoteOutput(
        address pool, 
        bool zeroToOne, 
        uint256 amountIn
    ) external view returns (uint256 amount) {
        (uint112 reserveIn, uint112 reserveOut) = _getReserves(
            IUniswapV2Pair(pool), 
            zeroToOne
        );

        amount = _getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
    }

    function quotePrice(
        IUniswapV2Pair pool,
        bool zeroToOne
    ) external view returns (uint256 price) {
        (uint112 reserveIn, uint112 reserveOut) = _getReserves(
            pool, 
            zeroToOne
        );
        price = (Decimal.from(reserveIn).div(reserveOut)).value;
    }

    function quoteReserves(
        address pool, 
        bool zeroToOne,
        bool V3
    ) external view returns (uint reserveIn, uint reserveOut){
        (reserveIn, reserveOut) = V3 
        ? _getBalances(IUniswapV3Pool(pool), zeroToOne)
        : _getReserves(IUniswapV2Pair(pool), zeroToOne);
    }

    function _getBalances(
        IUniswapV3Pool _pool, 
        bool _zeroToOne
    ) internal view returns (uint256 reserveIn, uint256 reserveOut){
        (reserveIn, reserveOut) = _zeroToOne 
        ? (_balance(_pool.token0(), address(_pool)), _balance(_pool.token1(), address(_pool))) 
        : (_balance(_pool.token1(), address(_pool)), _balance(_pool.token0(), address(_pool)));
    }

    function _balance(address _token, address _pool) private view returns (uint256) {
        (bool success, bytes memory data) =
            _token.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, _pool));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function _getReserves(
        IUniswapV2Pair _pool, 
        bool _zeroToOne
    ) internal view returns (uint112 reserveIn, uint112 reserveOut){
        (uint112 reserve0, uint112 reserve1, ) = _pool.getReserves();
        (reserveIn, reserveOut) = _zeroToOne 
        ? (reserve0, reserve1) 
        : (reserve1, reserve0);
    }
    // copy from UniswapV2Library
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    // V2
    function _getAmountIn(
        uint256 _amountOut,
        uint256 _reserveIn,
        uint256 _reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(
            _amountOut > 0, 
            "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        require(
            _reserveIn > 0 && _reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = _reserveIn.mul(_amountOut).mul(1000);
        uint256 denominator = _reserveOut.sub(_amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // copy from UniswapV2Library
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    // V2
    function _getAmountOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(
            _amountIn > 0, 
            "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT"
        );
        require(
            _reserveIn > 0 && _reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = _amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(_reserveOut);
        uint256 denominator = _reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

}

interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IERC20Minimal {
    function balanceOf(address account) external view returns (uint256);
}


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

library SafeMathCopy {
    // To avoid namespace collision between openzeppelin safemath and uniswap safemath

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Decimal {
    using SafeMathCopy for uint256;
    uint256 private constant BASE = 10 ** 18;

    struct D256 {
        uint256 value;
    }

    function zero() internal pure returns (D256 memory) {
        return D256({value: 0});
    }

    function one() internal pure returns (D256 memory) {
        return D256({value: BASE});
    }

    function from(uint256 a) internal pure returns (D256 memory) {
        return D256({value: a.mul(BASE)});
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({value: getPartial(a, BASE, b)});
    }

    function add(
        D256 memory self,
        uint256 b
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.add(b.mul(BASE))});
    }

    function sub(
        D256 memory self,
        uint256 b
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.mul(BASE))});
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.mul(BASE), reason)});
    }

    function mul(
        D256 memory self,
        uint256 b
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.mul(b)});
    }

    function div(
        D256 memory self,
        uint256 b
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.div(b)});
    }

    function pow(
        D256 memory self,
        uint256 b
    ) internal pure returns (D256 memory) {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({value: self.value});
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.add(b.value)});
    }

    function sub(
        D256 memory self,
        D256 memory b
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.value)});
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.value, reason)});
    }

    function mul(
        D256 memory self,
        D256 memory b
    ) internal pure returns (D256 memory) {
        return D256({value: getPartial(self.value, b.value, BASE)});
    }

    function div(
        D256 memory self,
        D256 memory b
    ) internal pure returns (D256 memory) {
        return D256({value: getPartial(self.value, BASE, b.value)});
    }

    function equals(
        D256 memory self,
        D256 memory b
    ) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(
        D256 memory self,
        D256 memory b
    ) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(
        D256 memory self,
        D256 memory b
    ) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(
        D256 memory self,
        D256 memory b
    ) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(
        D256 memory self,
        D256 memory b
    ) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) private pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    ) private pure returns (uint256) {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}
