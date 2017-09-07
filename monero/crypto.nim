import crypto_ops, hex

export crypto_ops.CryptoError

proc zeroOut*(secret: var Int32B) =
  ## Zero out a secret
  externDiscard(sc0(secret))
  # extern_discard is an extern C symbol to
  # prevent sc_0 from being optimized out

template withSecret*(secret: var Int32B, body: untyped) =
  ## Zero out secret after executing body
  body
  zeroOut secret

type
  SecretKey* = Int32B
  PublicKey* = Int32B
  KeyDerivation* = Int32B
  
proc `$`*(k: SecretKey): string = hex.encode k

proc decodeSecret*(h: string): SecretKey =
  ## Decode a hexdecimal encoded key.
  hex.decode h, result

proc check*(sk: SecretKey) =
  ## Takes as input some data and converts to a point on ed25519.
  if sc_check(sk) != 0:
    raise newException(CryptoError, "invalid secret key")

proc toPublicKey*(sk: SecretKey, result: var PublicKey) =
  var point: ge_p3
  check sk
  ge_scalarmult_base(point, sk)
  ge_p3_tobytes(result, point)

proc publicKey*(sk: SecretKey): PublicKey =
  toPublicKey sk, result

proc generateKeyDerivation*(pk: PublicKey; sk: SecretKey; result: var KeyDerivation) =
  var
    point: ge_p3
    point2: ge_p2
    point3: ge_p1p1
  check sk
  if ge_frombytes_vartime(point, pk) != 0:
    raise newException(CryptoError, "invalid public key")
  ge_scalarmult(point2, sk, point)
  ge_mul8(point3, point2)
  ge_p1p1_to_p2(point2, point3)
  ge_tobytes(result, point2)

proc reduce*(sk: SecretKey) = sc_reduce32 sk
