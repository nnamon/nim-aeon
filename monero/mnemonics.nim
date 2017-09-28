import address,
  endians, strutils

type Crc32* = uint32
const InitCrc32* = Crc32(-1)

proc createCrcTable(): array[0..255, Crc32] =
  for i in 0..255:
    var rem = i.Crc32
    for j in 0..7:
      if (rem and 1) > 0: rem = (rem shr 1) xor Crc32(0xedb88320)
      else: rem = rem shr 1
    result[i] = rem

const crc32table = createCrcTable()

proc crc32(buf: openArray[char]): Crc32 =
  result = InitCrc32
  for c in buf:
    result = (result shr 8) xor crc32table[(result and 0xff) xor ord(c)]
  result = not result

type Dictionary = object
  words: array[1626, string]
  uniqueLen: int

proc index(d: Dictionary; x: string): int32 =
  for i in 0..<d.words.len:
    block match:
      let y = d.words[i]
      for j in 0..d.uniqueLen:
        if x[j]  != y[j]:
          break match
      return i.int32
    dec result
  raise newException(SystemError, x & " not found in dictionary")

proc readDict(words: string; uniqueLen: int): Dictionary =
  var i: int
  for line in splitLines words:
    if line != "":
      result.words[i] = line
      inc i
  doAssert(i == result.words.len)
  result.uniqueLen = uniqueLen

type
  MnemonicLanguage* = enum
    German
    English
    Spanish
    French
    Italian
    Dutch
    Portuguese
    Russian
    Japanese
    Chinese_Simplified

import english

const
  EnglishWords = readDict(english.mnemonics, english.uniqueLen)
  SeedLen = 24

type MnemonicSeed* = array[SeedLen+1, string]

proc `$`*(seed: MnemonicSeed): string = join seed, " "

proc utf8prefix(s: string; n: int):  string =
  ## Reduce string 's' to 'n' printable characters.
  result = newStringOfCap max(n, s.len)
  var i = 0
  var n = n
  while n > 0 and i < s.len:
    result.add s[i]
    inc i
    while (i < s.len) and ((s[i].uint8 and 0xc0'u8) == 0x80'u8):
      result.add s[i]
      inc i
    dec n

proc checksumIndex(seed: openArray[string]; prefixLen: int): int =
  ## Find the checksum index within a seed.
  doAssert(seed.len in { SeedLen, SeedLen+1 })
  var trimmed = newStringOfCap(SeedLen * prefixLen)
  for i in 0..<SeedLen:
    let w = seed[i]
    if w.len > prefixLen:
      trimmed.add utf8prefix(w, prefixLen)
    else:
      trimmed.add w
  result = trimmed.crc32 mod SeedLen

proc keyToWords*(sk: SpendSecret; lang = English): MnemonicSeed =
  ## Generate mnemonic seed for a spend secret key.
  #let dict = case lang
  #of English: EnglishWords
  let dict = EnglishWords

  let dictLen = dict.words.len.uint32
  # 8 bytes -> 3 words.  8 digits base 16 -> 3 digits base 1626
  for i in 0..<(sk.len div 4):
    var val: uint32
    for j in 0..<sizeof(val):
      val = val or (sk[(i*4)+j].uint32 shl (8*j))
      #convert to little-endian without pointers
    let
      w1 = val mod dictLen
      w2 = ((val div dictLen) + w1) mod dictLen
      w3 = (((val div dictLen) div dictLen) + w2) mod dictLen
    let o = i * 3
    result[o+0] = dict.words[w1]
    result[o+1] = dict.words[w2]
    result[o+2] = dict.words[w3]
  result[result.high] = result[checksumIndex(result, dict.uniqueLen)]

proc wordsToKey*(words: openArray[string]; lang = English): SpendSecret =
  ## Recover a key from a mnemonic seed.
  doAssert(words.len in { SeedLen, SeedLen+1 })
  #let dict = case lang
  #of English: EnglishWords
  let dict = EnglishWords

  var indices: array[SeedLen, int32]
  for i in 0..<SeedLen:
    indices[i] = dict.index words[i]
  let dictLen = dict.words.len
  for i in 0..<(SeedLen div 3):
    let
      o = i * 3
      w1 = indices[o+0]
      w2 = indices[o+1]
      w3 = indices[o+2]
    var val = w1 +
        dictLen * (((dictLen - w1) + w2) mod dictLen) +
        dictLen * dictLen * (((dictLen - w2) + w3) mod dictLen)
    if not (val mod dictLen == w1):
      raise newException(SystemError, "bad mnemonic")
    littleEndian32(addr result[i*4], addr val)
  if words.len > SeedLen:
    let checkIndex = checksumIndex(words, dict.uniqueLen)
    if words[checkIndex] != words[SeedLen]:
      raise newException(SystemError, "mnemonic checksum failed")
