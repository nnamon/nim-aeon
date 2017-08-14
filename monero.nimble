version       = "0.1.0"
author        = "Emery Hemingway"
description   = "Libraries and utilites related to Monero, a CryptoNote cryptocurrency."
license       = "MIT"

requires "nim >= 0.17.1"

bin = @["monero/monero_vanity"]
skipDirs = @["tests"]

task crypto_tests, "Runs the crypto tests":
  exec "nim c -r tests/crypto_tests"
