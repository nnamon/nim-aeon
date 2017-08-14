import crypto
import streams, strutils, parseutils, hex

var
  line = newStringOfCap 49570
  token = newStringOfCap 128
  testFile = newFileStream("tests/crypto_tests.txt", fmRead)

var
  generate_key_derivation: int
  secret_key_to_public_key: int

while testFile.readLine(line):
  var argPos = parseUntil(line, token, ' ')+1

  case token:

  of "secret_key_to_public_key":
    var
      secret: SecretKey
      expected1: bool
      actual1 = false
      expected2, actual2: PublicKey

    inc(argPos, parseUntil(line, token, ' ', argPos)+1)
    hex.decode token, secret

    inc(argPos, parseUntil(line, token, ' ', argPos)+1)
    expected1 = parseBool token
    if expected1:
      inc(argPos, parseUntil(line, token, ' ', argPos)+1)
      hex.decode token, expected2

    if expected1:
      secret.toPublicKey actual2
      actual1 = true
    else:
      try:
        secret.toPublicKey actual2
        actual1 = true
      except CryptoError:
        actual1 = false

    if expected1 != actual1 or (expected1 and (expected2 != actual2)):
      echo line
    else:
      inc secret_key_to_public_key

  of "generate_key_derivation":
    var
      key1: PublicKey
      key2: SecretKey
      expected1, actual1: bool
      expected2, actual2: KeyDerivation

    inc(argPos, parseUntil(line, token, ' ', argPos)+1)
    hex.decode token, key1

    inc(argPos, parseUntil(line, token, ' ', argPos)+1)
    hex.decode token, key2

    inc(argPos, parseUntil(line, token, ' ', argPos)+1)
    expected1 = parseBool token

    if expected1:
      inc(argPos, parseUntil(line, token, ' ', argPos)+1)
      hex.decode token, expected2

    if expected1:
      generateKeyDerivation(key1, key2, actual2)
      actual1 = true
    else:
      try:
        generateKeyDerivation(key1, key2, actual2)
        actual1 = true
      except CryptoError:
        actual1 = false
    if expected1 != actual1 or (expected1 and expected2 != actual2):
      echo line
    else:
      inc generate_key_derivation

close testFile

echo "tests passed:"
echo "\tsecret_key_to_public_key\t", secret_key_to_public_key
echo "\tgenerate_key_derivation\t", generate_key_derivation
