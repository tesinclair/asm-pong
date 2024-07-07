#!/usr/bin/env python3

"""
This is soley for documenting and testing high level
versions of the algorithms i'll be using
"""

import math

def sqrt(n):
    """ 
    A very simple square root, with a focus on
    simplicity of implementation.

    The key is that I do not need decimals, so all square
    roots are rounded up
    """
    
    guess = math.ceil(n / (n/10))

    while (guess**2 > n):
        guess -= 1

    while (guess**2 < n):
        guess += 1

    return guess

if __name__ == "__main__":
    assert sqrt(25) == 5, f"Failed with val: {sqrt(25)}"
    assert sqrt(24) == 5, f"Failed with val: {sqrt(24)}"
    assert sqrt(26) == 6, f"Failed with val: {sqrt(26)}"
    assert sqrt(1) == 1, f"Failed with val: {sqrt(1)}"
    assert sqrt(2) == 2, f"Failed with val: {sqrt(2)}"
    assert sqrt(3) == 2, f"Failed with val: {sqrt(3)}"
    
    print("Square root 40395: ", sqrt(40395))
    print("Actual: ", math.sqrt(40395))
