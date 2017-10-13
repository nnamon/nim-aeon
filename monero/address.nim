import crypto, hex, base58.cryptonote

export `$`, decodeSecret, check, PublicKey

import sha3

type
  SpendSecret* = SecretKey
  ViewSecret* = SecretKey

  Address* = ref object
    spend, view: PublicKey

proc toViewSecret*(spend: SpendSecret; result: var ViewSecret) =
  var ctx: SHA3
  sha3_init ctx, Keccak256
  sha3_update ctx, spend
  let d = sha3_final ctx
  for i in 0..<result.len:
    result[i] = d[i]
  reduce result

proc viewSecret*(spend: SpendSecret): ViewSecret = spend.toViewSecret result

proc address*(spend: SpendSecret; view: ViewSecret): Address =
  new result
  spend.toPublicKey result.spend
  view.toPublicKey result.view

proc address*(spend: SpendSecret): Address =
  var view = spend.viewSecret
  withSecret view:
    result = address(spend, view)

const NetworkTag* = 0x12

proc `$`*(a: Address): string =
  # not very efficient
  var
    buf: array[69, uint8]
    keccak: SHA3
  sha3_init keccak, Keccak256
  sha3_update keccak, [NetworkTag]
  buf[0] = NetworkTag
  for i in 0..31:
    buf[i+1] = a.spend[i]
  sha3_update keccak, a.spend
  for i in 0..31:
    buf[i+33] = a.view[i]
  sha3_update keccak, a.view
  let digest = sha3_final keccak
  for i in 0..3:
    buf[i+65] = digest[i]

  cryptonote.encode(buf)
