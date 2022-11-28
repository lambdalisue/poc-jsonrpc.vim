vim9script

export def Connect(host: string, port: number): channel
  var addr = printf("%s:%s", host, port)
  var store = {
    "previous": "",
  }
  var chan = ch_open(addr, {
    "mode": "raw",
    "callback": (chan, msg) => OnReceive(store, chan, msg),
    "noblock": true,
  })
  return chan
enddef

export def Close(chan: channel): void
  call ch_close(chan)
enddef

def OnReceive(store: dict<string>, chan: channel, msg: string): void
  var records = split(store.previous .. msg, "\n", true)
  store.previous = remove(records, -1)
  for record in records
    var request = json_decode(record)
    var response = Dispatch(request)
    if response == null
      continue
    endif
    call ch_sendraw(chan, json_encode(response))
  endfor
enddef

def Dispatch(request: any): any
  if type(request) == v:t_list
    return Batch(request)
  else
    return Call(request)
  endif
enddef

def Batch(cmds: list<dict<any>>): any
  var results = []
  for cmd in cmds
    var result = Call(cmd)
    if result != null
      call add(results, result)
    endif
  endfor
  return len(results) > 0 ? results : null
enddef

def Call(cmd: dict<any>): any
  var result: dict<any>
  try
    result = {"result": call(cmd.method, cmd.params)}
  catch
    result = {"error": {
      "coce": 1,
      "message": v:exception .. "\n" .. v:throwpoint,
    }}
  endtry
  if !has_key(cmd, "id")
    return null
  endif
  return extend({"jsonrpc": "2.0", "id": cmd.id}, result)
enddef
