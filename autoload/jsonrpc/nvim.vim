function! jsonrpc#nvim#Connect(host, port) abort
  return luaeval('require("jsonrpc").connect(_A[1], _A[2])', [a:host, a:port])
endfunction

function! jsonrpc#nvim#Close(chan) abort
  return luaeval('require("jsonrpc").close(_A[1])', [a:chan])
endfunction
