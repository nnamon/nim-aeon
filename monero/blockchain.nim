import json

import ./crypto

type
  Amount* = distinct uint64

#proc `*` (x: Dollar, y: int): Dollar {.borrow.}
#proc `*` (x: int, y: Dollar): Dollar {.borrow.}
#proc `div` (x: Dollar, y: int): Dollar {.borrow.}

type
  ExtraKind = enum
    ExtraPadding = 0x00
    ExtraPubKey = 0x01
    ExtraNonce = 0x02
    ExtraMergeMining = 0x03
    ExtraMysteriousMinerGate = 0xDE

  Transaction* = object
     outer, inner: JsonNode

  Block* = JsonNode

proc parseTransaction*(js: JsonNode): Transaction =
  result.outer = js
  result.inner = parseJson js["as_json"].getStr
  echo "inner keys:"
  for k, v in result.inner.pairs:
    echo "\t", k
  echo "vin: ", result.inner["vin"]
  echo "vout: ", result.inner["vout"]

proc inPool*(tx: Transaction): bool =
  tx.outer["in_pool"].getBVal

proc version*(tx: Transaction): int =
  tx.inner["version"].getNum.int

proc unlockTime*(tx: Transaction): BiggestInt =
  tx.inner["unlock_time"].getNum

proc outputs*(tx: Transaction; result: var seq[(Amount, string)]) =
  let js = tx.inner["vout"].getElems
  result.setLen js.len
  for i in result.low .. result.high:
    result[i][0] = js[i]["amount"].getNum.Amount
    result[i][1] = js[i]["target"]["key"].getStr

iterator outputs*(tx: Transaction): (Amount, string) =
  var outs = newSeq[(Amount, string)]()
  tx.outputs outs
  for o in outs.items: yield o

iterator extraPubKeys(tx: Transaction): PublicKey =
  let js = tx.inner["extra"].getElems
  var i = 0
  while i < js.len:
    case js[i].getNum.ExtraKind
      of ExtraPadding: echo "ExtraPadding"
      of ExtraPubkey:
        echo "ExtraPubkey"
        var result: PublicKey
        assert(js.len > result.len)
        for j in result.low .. result.high:
          inc i
          result[j] = js[i].getNum.uint8
        inc i
        yield result
        continue
      of ExtraNonce:
        echo "ExtraNonce"
        inc i
        let len = js[i].getNum.int
        inc i
        echo "next byte is ", len, ", ", js.len-i, " remaining bytes"
        i = i + len
        continue
      of ExtraMergeMining: echo "ExtraMergeMining"
      of ExtraMysteriousMinerGate: echo "ExtraMysteriousMinerGate"
      else:
        echo "extra tag byte not matched"
    break

proc derivation*(tx: Transaction, sk: var SecretKey, d: var KeyDerivation): bool =
  for key in tx.extraPubKeys:
    var pk = key
    if generateKeyDerivation(pk, sk, d):
      return true
  false
