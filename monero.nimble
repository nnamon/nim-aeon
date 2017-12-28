version       = "0.1.1"
author        = "Emery Hemingway"
description   = "Libraries and utilites related to Monero, a CryptoNote cryptocurrency."
license       = "MIT"

requires "nim >= 0.17.1"
requires "base58 >= 0.1.1"

bin = @["monero/monero_vanity"]
skipDirs = @["tests"]

task tests, "Runs tests":
  exec "nim c -r tests/crypto_tests"
  exec "nim c -r tests/mnemonic_tests"
