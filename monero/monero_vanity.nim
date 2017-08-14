import address, mnemonics, pcg, base58, crypto
import strutils, threadpool, cpuInfo, locks

const FinalMsg = """

Write the mnemonic seed on paper and keep it in a safe place.
The spend secret key has been written to file.
"""

var
  chan: Channel[SpendSecret]
  lock: Lock

open chan
initLock lock
acquire lock

proc randInt(): uint64 =
  let random = open "/dev/random"
  while true:
    if random.readBuffer(addr result, sizeof(result)) == sizeof(result):
      break
  close random

proc bruteforce(index: uint64; prefix: string) =
  var
    b58 = newString(base58.FullEncodedBlockSize)
    buf: array[33, uint8]
    key: SpendSecret
    pcg = Pcg32(state: randInt(), inc: index)
  buf[0] = NetworkTag
  while true:
    for i in 0..7:
      var x = pcg.next
      copyMem(addr key[i*4], addr x, 4)
    key.reduce
    key.toPublicKey cast[var PublicKey](addr buf[1])
    base58.encodeBlock(b58, 0, buf, 0, FullBlockSize)
    if b58.continuesWith(prefix, 2):
      withSecret key:
        chan.send key
      acquire lock


stdout.write "Enter desired Monero address prefix: "
let prefix = stdin.readLine()
stdout.writeLine "\nbruteforcing '", prefix, "'..."

for i in 1..countProcessors():
  spawn bruteforce(i.uint64, prefix)

var key = chan.recv
withSecret key:
  let b56Addr = $key.address
  var view = key.viewSecret
  withSecret view:
    stdout.writeLine "\n", b56Addr
    let words = key.keyToWords
    stdout.writeLine "\n",
      words[0..3].join(" "), "\n",
      words[4..7].join(" "), "\n",
      words[8..11].join(" ")
    writeFile(b56Addr & ".view", $view & "\n")
    stdout.writeLine FinalMsg

flushFile stdout
