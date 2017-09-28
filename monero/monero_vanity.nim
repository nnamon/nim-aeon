import address, mnemonics, pcg, base58, crypto
import strutils, threadpool, cpuInfo, locks

const FinalMsg = """

Write the mnemonic seed on paper and keep it in a safe place.
The spend secret key has been written to file.
"""

var chan: Channel[SpendSecret]
open chan

proc found(key: SpendSecret) =
  let b56Addr = $key.address
  var view = key.viewSecret
  withSecret view:
    stdout.writeLine "\n", b56Addr
    let words = key.keyToWords
    stdout.writeLine "\n",
      words[0..7].join(" "), "\n",
      words[8..15].join(" "), "\n",
      words[16..23].join(" "), "\n",
      words[24]
    writeFile(b56Addr & ".view", $view & "\n")
    stdout.writeLine FinalMsg

proc bruteforce(index, seed: uint64; prefix: string) =
  var
    b58 = newString(base58.FullEncodedBlockSize)
    buf: array[33, uint8]
    key: SpendSecret
    pcg = Pcg32(state: seed, inc: index)
  buf[0] = NetworkTag
  while true:
    for i in countup(0, <key.len, sizeof(uint32)):
      var x = pcg.next
      copyMem(addr key[i], addr x, sizeof(uint32))
    key.reduce
    key.toPublicKey cast[var PublicKey](addr buf[1])
    base58.encodeBlock(b58, 0, buf, 0, FullBlockSize)
    if b58.continuesWith(prefix, 2):
      withSecret key:
        chan.send key
      break

when defined(genode):
  const promptMsg = "Enter desired Monero address prefix: "
  stdout.write promptMsg
  var
    prefix = newString(FullEncodedBlockSize-2) # that would take a long time
    off = 0
    #linePos = promptMsg.len
  block input:
    while off < (prefix.len-2):
      if stdin.readChars(prefix, off, 1) == 1:
        let c = prefix[off]
        if not base58.Alphabet.contains(c):
          if c in NewLines:
            break input
          elif c == 0x08.char and off > 0:
            prefix[off+1] = ' '
            prefix[off+2] = 0x08.char
            discard stdout.writeChars(prefix, off, 3)
            dec off
            #dec linePos
        else:
          let n = stdout.writeChars(prefix, off, 1)
          off.inc n
          #linePos.inc n
  prefix.setLen off
  stdout.write ". bruteforcing"
else:
  import os
  let params = commandLineParams()
  if params.len != 1:
    stderr.writeLine "please supply a Monero address prefix"
    quit 1
  let prefix = params[0]
  for c in prefix.items:
    if not base58.Alphabet.contains(c):
      stderr.writeLine "character '", c, "' not in base56 alphabet"
      quit 1
  stdout.writeLine "gathering entropy and bruteforcing '", prefix, "'..."

proc randInt(): uint64 =
  let random = open "/dev/random"
  while true:
    if random.readBuffer(addr result, sizeof(result)) == sizeof(result):
      break
  close random

for i in 1..countProcessors():
  spawn bruteforce(i.uint64, randInt(), prefix)
  when defined(genode):
    stdout.write "."
when defined(genode):
  stdout.write "\n"

var key = chan.recv()
withSecret key:
  found key

echo "all done"
