import endians

const
  FullBlockSize* = 8
  FullEncodedBlockSize* = 11
  EncodedBlockSizes = [ 0, 2, 3, 5, 6, 7, 9, 10, 11 ]

  Alphabet* = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  AlphabetSize = Alphabet.len
  ReverseAlphabetSize = Alphabet[Alphabet.high].int - Alphabet[Alphabet.low].int + 1

proc reverseAlphabet(): array[ReverseAlphabetSize, int8] =
  for i in 0..<result.len:
    result[i] = -1
  for i in 0..<AlphabetSize:
    let j = Alphabet[i].int - Alphabet[0].int
    result[j] = i.int8

proc decodedBlockSizes(): array[EncodedBlockSizes[FullBlockSize]+1, int] =
  for i in 0..<result.len:
    result[i] = -1
  for i in 0..FullBlockSize:
    result[EncodedBlockSizes[i]] = i

const
  ReverseAlphabet = reverseAlphabet()
  DecodedBlockSizes = decodedBlockSizes()

proc reverseChar(c: char): uint64 =
  let i = c.int - Alphabet[0].int
  if i > ReverseAlphabet.high:
    raise newException(SystemError, "invalid base58 character")
  ReverseAlphabet[i].uint64

proc uint8beTo64[T: char|int8|uint8](x: openArray[T]; off, n: int): uint64 =
  for i in off..off+n-1:
    result = (result shl 8) or x[i].uint64

proc uint64to8be[T: char|int8|uint8](num: uint64; n: int; dst: var openArray[T]; off: int) =
  doAssert(1 <= n and n <= 8)
  var x = num shl (8*(8 - n))
  var tmp: array[8, T]
  bigEndian64(addr tmp, addr x)
  for i in 0..<n:
    dst[off+i] = tmp[i]

proc encodeBlock*[T: char|int8|uint8](str: var openArray[char]; strOff: int; bin: openArray[T]; binOff, blkLen: int) =
  var num = uint8beTo64(bin, binOff, blkLen)
  for i in countdown(<(strOff + EncodedBlockSizes[blkLen]), strOff):
    let remainder = num mod AlphabetSize
    num = num div AlphabetSize
    str[i] = Alphabet[remainder.int]

proc encode*[T: char|int8|uint8](bin: openArray[T]): string =
  let
    fullBlockCount = bin.len div FullBlockSize
    lastBlockSize = bin.len mod FullBlockSize
  result = newString fullBlockCount * FullEncodedBlockSize + EncodedBlockSizes[lastBlockSize]

  for i in 0 .. <fullBlockCount:
    encodeBlock(result, i*FullEncodedBlockSize, bin, i*FullBlockSize, FullBlockSize)

  if lastBlockSize > 0:
    encodeBlock(result, fullBlockCount*FullEncodedBlockSize, bin, fullBlockCount*FullBlockSize, lastBlockSize)

proc hiDword(x: uint64): uint64 {.inline.} = x shr 32
proc loDword(x: uint64): uint64 {.inline.} = x and 0xffffffff'u64

type Uint128 = tuple[hi, lo: uint64]

proc mul128(x, y: uint64): Uint128 =
  # x = ab = a * 2^32 + b
  # y = cd = c * 2^32 + d
  # ab * cd = a * c * 2^64 + (a * d + b * c) * 2^32 + b * d
  let
    a = hiDword x
    b = loDword x
    c = hiDword y
    d = loDword y

    ac = a * c
    ad = a * d
    bc = b * c
    bd = b * d

    adbc = ad + bc
    adbcCarry = if adbc < ad: 1'u64 else: 0'u64

  # x * y = result.hi * 2^64 + result.lo
  result.lo = bd + (adbc shl 32)
  let resultLoCarry: uint64 = if result.lo < bd: 1'u64 else: 0'u64
  result.hi = ac + (adbc shr 32) + (adbcCarry shl 32) + resultLoCarry
  doAssert(ac <= result.hi)

proc raiseOverflow =
  raise newException(OverflowError, "base58 overflow")

proc decodeBlock[T: char|int8|uint8](bin: var openArray[T]; binOff: int; str: string; strOff, blkLen: int) =
  doAssert(blkLen > 0 and blkLen <= FullEncodedBlockSize)
  
  let resSize = DecodedBlockSizes[blkLen]
  assert(resSize > 0)
  var
    resNum: uint64 = 0
    order: uint64 = 1
  for i in countdown(<(blkLen+strOff), strOff):
    let digit = reverseChar str[i]
    if digit < 0: raise newException(SystemError, "invalid base58 character")
    let product = mul128(order, digit)
    let tmp = resNum + product.lo
    doAssert(tmp >= res_num and product.hi == 0)
    resNum = tmp
    order = order * AlphabetSize
  
  if resSize < FullBlockSize and (1.uint64 shl (8 * resSize)) <= resNum:
    raiseOverflow()
  uint64to8be(resNum, resSize, bin, binOff)

proc decode*[T: char|int8|uint8](str: string; result: var openArray[T]) =
  let
    fullBlockCount = str.len div FullEncodedBlockSize
    lastBlockSize = str.len mod FullEncodedBlockSize
    lastBlockDecodedSize = DecodedBlockSizes[lastBLockSize]
  if lastBlockDecodedSize < 0:
    raise newException(SystemError, " invalid base58 length")
  doAssert(result.len >= fullBlockCount * FullBlockSize + lastBlockDecodedSize)

  for i in 0..<fullBlockCount:
    decodeBlock(result, i*FullBlockSize, str, i*FullEncodedBlockSize, FullEncodedBlockSize)

  if lastBlockSize > 0:
    decodeBlock(result, fullBlockCount*FullBlockSize, str, fullBlockCount*FullEncodedBlockSize, lastBlocksize)

proc decode*(str: string): string =
  let
    fullBlockCount = str.len div FullEncodedBlockSize
    lastBlockSize = str.len mod FullEncodedBlockSize
  let
    lastBlockDecodedSize = DecodedBlockSizes[lastBLockSize]
  result = newString(fullBlockCount * FullBlockSize + lastBlockDecodedSize)
  decode(str, result)

when isMainModule:
  const control = "A1N3xB5e9whBC1UWprQhR5B6fv9A8nRRLKud4Ussh34zbaAfgbcFsA9UpsNrdemy9eUT9V5PyDfgwFQQohSZteaeBJxfMuE"
  let test = encode(decode(control))
  doAssert(test == control)