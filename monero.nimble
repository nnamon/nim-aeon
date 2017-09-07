version       = "0.1.0"
author        = "Emery Hemingway"
description   = "Libraries and utilites related to Monero, a CryptoNote cryptocurrency."
license       = "MIT"

requires "nim >= 0.17.1"

bin = @["monero/monero_vanity"]
skipDirs = @["tests"]

task tests, "Runs tests":
  exec "nim c -r tests/crypto_tests"
  exec "nim c -r tests/mnemonic_tests"

task docs, "Generate documentation and create git tag":
  exec "nim doc2 monero/address.nim"
  exec "nim doc2 monero/base58.nim"
  exec "nim doc2 monero/crypto_ops.nim"
  exec "nim doc2 monero/crypto.nim"
  exec "nim doc2 monero/mnemonics.nim"
