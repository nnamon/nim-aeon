{.compile: "crypto-ops.c".}
{.compile: "crypto-ops-data.c".}

{.pragma: cryptoOp, importc, header: "crypto-ops.h".}

type
  CryptoError* = object of Exception

  Int32B* = array[32, uint8]

  ge_p1p1* {.cryptoOp.} = object
  ge_p2* {.cryptoOp.} = object
  ge_p3* {.cryptoOp.} = object

proc sc_check*(s: Int32B): cint {.cryptoOp.}

proc ge_frombytes_vartime*(h: var ge_p3; s: Int32B): int {.cryptoOp.}

proc ge_scalarmult*(r: var ge_p2; a: Int32B; A: var ge_p3) {.cryptoOp.}

proc ge_mul8*(r: var ge_p1p1; t: var ge_p2) {.cryptoOp.}

proc ge_p1p1_to_p2*(r: var ge_p2; p: var ge_p1p1) {.cryptoOp.}
  ## There are different representations of curve points for ed25519, this converts between them.

proc ge_tobytes*(s: Int32B; h: var ge_p2) {.cryptoOp.}

proc ge_scalarmult_base*(h: var ge_p3; a: Int32B) {.cryptoOp.}

proc ge_p3_tobytes*(s: Int32B, h: var ge_p3) {.cryptoOp.}

proc sc_reduce32*(s: Int32B) {.cryptoOp.}

proc sc_0*(s: Int32B): cint {.cryptoOp.}

proc extern_discard*(x: cint) {.cryptoOp.}
