# *Really* minimal PCG32 code / (c) 2014 M.E. O'Neill / pcg-random.org
# Licensed under Apache License 2.0 (NO WARRANTY, etc. see website)

# Nim translation by Emery Hemingway

type Pcg32* = object
  state*, inc*: uint64

proc next*(rng: var Pcg32): uint32 =
  let oldState = rng.state
  # Advance internal state
  rng.state = oldState * 6364136223846793005'u64 + (rng.inc or 1'u64);
  # Calculate output function (XSH RR), uses old state for max ILP
  let
    xorshifted = (((oldState shr 18) xor oldState) shr 27).uint32
    rot = (oldState shr 59).uint32
  (xorshifted shr rot) or (xorshifted shl ((0'u32 - rot) and 31))
