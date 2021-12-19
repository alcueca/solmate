// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

contract FixedPointMathLibTest is DSTestPlus {
    function testFMul() public {
        assertEq(FixedPointMathLib.fmul(2.5e27, 0.5e27, FixedPointMathLib.RAY), 1.25e27);
        assertEq(FixedPointMathLib.fmul(2.5e18, 0.5e18, FixedPointMathLib.WAD), 1.25e18);
        assertEq(FixedPointMathLib.fmul(2.5e8, 0.5e8, FixedPointMathLib.YAD), 1.25e8);
    }

    function testFMulEdgeCases() public {
        assertEq(FixedPointMathLib.fmul(0, 1e18, FixedPointMathLib.WAD), 0);
        assertEq(FixedPointMathLib.fmul(1e18, 0, FixedPointMathLib.WAD), 0);
        assertEq(FixedPointMathLib.fmul(0, 0, FixedPointMathLib.WAD), 0);
        assertEq(FixedPointMathLib.fmul(1e18, 1e18, 0), 0);
    }

    function testFDiv() public {
        assertEq(FixedPointMathLib.fdiv(1e27, 2e27, FixedPointMathLib.RAY), 0.5e27);
        assertEq(FixedPointMathLib.fdiv(1e18, 2e18, FixedPointMathLib.WAD), 0.5e18);
        assertEq(FixedPointMathLib.fdiv(1e8, 2e8, FixedPointMathLib.YAD), 0.5e8);
    }

    function testFDivEdgeCases() public {
        assertEq(FixedPointMathLib.fdiv(1e8, 1e18, 0), 0);
        assertEq(FixedPointMathLib.fdiv(0, 1e18, FixedPointMathLib.WAD), 0);
    }

    function testFailFDivZeroY() public pure {
        FixedPointMathLib.fdiv(1e18, 0, FixedPointMathLib.WAD);
    }

    function testFailFDivZeroXY() public pure {
        FixedPointMathLib.fdiv(0, 0, FixedPointMathLib.WAD);
    }

    function testFailFDivXYB() public pure {
        FixedPointMathLib.fdiv(0, 0, 0);
    }

    function testFPow() public {
        assertEq(FixedPointMathLib.fpow(2e27, 2, FixedPointMathLib.RAY), 4e27);
        assertEq(FixedPointMathLib.fpow(2e18, 2, FixedPointMathLib.WAD), 4e18);
        assertEq(FixedPointMathLib.fpow(2e8, 2, FixedPointMathLib.YAD), 4e8);
    }

    function testSqrt() public {
        assertEq(FixedPointMathLib.sqrt(2704), 52);
        assertEq(FixedPointMathLib.sqrt(110889), 333);
        assertEq(FixedPointMathLib.sqrt(32239684), 5678);
    }

    function testMin() public {
        assertEq(FixedPointMathLib.min(4, 100), 4);
        assertEq(FixedPointMathLib.min(500, 400), 400);
        assertEq(FixedPointMathLib.min(10000, 10001), 10000);
        assertEq(FixedPointMathLib.min(1e18, 0.1e18), 0.1e18);
    }

    function testMax() public {
        assertEq(FixedPointMathLib.max(4, 100), 100);
        assertEq(FixedPointMathLib.max(500, 400), 500);
        assertEq(FixedPointMathLib.max(10000, 10001), 10001);
        assertEq(FixedPointMathLib.max(1e18, 0.1e18), 1e18);
    }

    function testFMul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) public {
        // Convert cases where x * y overflows into useful test cases.
        unchecked {
            while (x != 0 && (x * y) / x != y) {
                x /= 2;
                y /= 2;
            }
        }

        assertEq(FixedPointMathLib.fmul(x, y, baseUnit), baseUnit == 0 ? 0 : (x * y) / baseUnit);
    }

    function testFailFMulOverflow(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) public pure {
        // Ignore cases where x * y does not overflow.
        unchecked {
            if ((x * y) / x == y) revert();
        }

        FixedPointMathLib.fmul(x, y, baseUnit);
    }

    function testFDiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) public {
        // Convert cases where x * baseUnit overflows into useful test cases.
        unchecked {
            while (x != 0 && (x * baseUnit) / x != baseUnit) {
                x /= 2;
                baseUnit /= 2;
            }
        }

        // y is zero will cause a revert, so set y to a "random" value
        if (y == 0) {
            y = uint256(keccak256(abi.encode(x, baseUnit)));
        }

        assertEq(FixedPointMathLib.fdiv(x, y, baseUnit), (x * baseUnit) / y);
    }

    function testFailFDivOverflow(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) public pure {
        // Ignore cases where x * baseUnit does not overflow.
        unchecked {
            if ((x * baseUnit) / x == baseUnit) revert();
        }

        FixedPointMathLib.fdiv(x, y, baseUnit);
    }

    function testFailFDivYZero(uint256 x, uint256 baseUnit) public pure {
        FixedPointMathLib.fdiv(x, 0, baseUnit);
    }

    function testSqrt(uint256 x) public {
        uint256 root = FixedPointMathLib.sqrt(x);
        uint256 next = root + 1;

        // Convert cases where next * next overflows into useful test cases.
        unchecked {
            while (next * next < next) {
                x /= 2;
                root = FixedPointMathLib.sqrt(x);
                next = root + 1; // this cannot overflow since we'll never have a square root equal to type(uint256).max
            }
        }

        assertTrue(root * root <= x && next * next > x);
    }

    function testMin(uint256 x, uint256 y) public {
        if (x < y) {
            assertEq(FixedPointMathLib.min(x, y), x);
        } else {
            assertEq(FixedPointMathLib.min(x, y), y);
        }
    }

    function testMax(uint256 x, uint256 y) public {
        if (x > y) {
            assertEq(FixedPointMathLib.max(x, y), x);
        } else {
            assertEq(FixedPointMathLib.max(x, y), y);
        }
    }
}
