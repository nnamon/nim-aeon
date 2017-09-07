import strutils, unittest, mnemonics, address, random

const
  controlHex = "c9bc273a33eff7296d273f1aba96f8f733fc02e12220655695fbcafb1630f402"
  controlKey = controlHex.decodeSecret
  controlWords = splitWhitespace """
    unnoticed vessel cohesive ruined apply duke snout goes
    jogger tomorrow industrial hiker soil pests megabyte raking
    venomous evolved audio tsunami tirade debut vaults viking hiker"""

suite controlHex:

  test "keyToWords":
    let testWords = controlKey.keyToWords
    for i in 0..<controlWords.len:
      doAssert(controlWords[i] == testWords[i])

  test "wordsToKey":
    let testKey = controlWords.wordsToKey
    doAssert(controlKey == testKey)

suite "random":

  proc randomKey: SpendSecret =
    random.randomize()
    for i in 0..<result.len:
      result[i] = random(256).uint8

  for i in 0..8:
    test "mutual reversibility " & $i:
      let
        control = randomKey()
        words = control.keyToWords
        test = words.wordsToKey
      doAssert(test == control)
