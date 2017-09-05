import httpclient, net, json

import blockchain

type
  DaemonClient* = ref DaemonClientObj
  DaemonClientObj = object
    http: HttpClient
    url: string

proc newDaemonClient*(host: string, port: Port): DaemonClient =
  new result
  result.http = newHttpClient()
  result.http.headers = newHttpHeaders({ "Content-Type": "application/json" })
  result.url = "http://" & host & ":" & $(port.int) & "/"

proc close*(c: DaemonClient) =
  close c.http

proc request(c: DaemonClient; m: string): JsonNode =
  let
    body = %*{
      "jsonrpc" : "2.0",
      "id" : "0",
      "method" : m
      #"params" : ""
    }
    resp = c.http.request(
      c.url & "json_rpc", httpMethod = HttpPost, body = $body)
    js = parseJson resp.body
  if js.hasKey "error":
    raise newException(SystemError, $js)
  result = js["result"]

proc request(c: DaemonClient; m: string; params: JsonNode): JsonNode =
  let
    body = %*{
      "jsonrpc" : "2.0",
      "id" : "0",
      "method" : m,
      "params" : params
    }
    resp = c.http.request(
      c.url & "json_rpc", httpMethod = HttpPost, body = $body)
    js = parseJson resp.body
  if js.hasKey "error":
    raise newException(SystemError, $js["error"]["message"])
  result = js["result"]

proc requestExt(c: DaemonClient; m: string; params: JsonNode): JsonNode =
  let
    resp = c.http.request(
      c.url & m, httpMethod = HttpPost, body = $params)
  result = parseJson resp.body

proc getBlockCount*(c: DaemonClient): int =
  let js = c.request "getblockcount"
  js["count"].getNum.int

proc getBlock*(c: DaemonClient; height: int): JsonNode =
  c.request "getblock", %*{"height":height}

proc getBlock*(c: DaemonClient; hash: string): JsonNode =
  c.request "getblock", %*{"hash":hash}

#proc getTransactions*(c: DaemonClient; hashes: openArray[string]): JsonNode

proc getTransactions*(c: DaemonClient; hashes: JsonNode): JsonNode =
  assert(hashes.kind == JArray)
  let js = c.requestExt(
    "gettransactions", %*{"decode_as_json":true, "txs_hashes":hashes})
  result = js["txs"]

iterator transactions*(d: DaemonClient; b: Block): Transaction =
  let txs = d.getTransactions b["tx_hashes"]
  for i in txs.items:
    yield (parseTransaction i)
