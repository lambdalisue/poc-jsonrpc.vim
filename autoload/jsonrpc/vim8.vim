function! jsonrpc#vim8#Connect(host, port) abort
  let l:addr = printf('%s:%s', a:host, a:port)
  let l:store = {
        \ 'previous': '',
        \}
  let l:chan = ch_open(l:addr, {
        \ 'mode': 'raw',
        \ 'callback': funcref('s:on_receive', [l:store]),
        \ 'noblock': v:true,
        \})
  
endfunction

function! jsonrpc#vim8#Close(chan) abort
  call ch_close(a:chan)
endfunction

function! s:on_receive(store, chan, msg) abort
  let l:records = split(a:store.previous .. a:msg, '\n', v:true)
  let a:store.previous = remove(l:records, -1)
  for l:record in l:records
    let l:request = json_decode(l:record)
    let l:response = s:dispatch(l:request)
    if l:response is# v:null
      continue
    endif
    call ch_sendraw(a:chan, json_encode(l:response))
  endfor
endfunction

function! s:dispatch(request) abort
  if type(a:request) is# v:t_list
    return s:batch(a:request)
  else
    return s:call(a:request)
  endif
endfunction

function! s:batch(cmds) abort
  let l:results = []
  for l:cmd in a:cmds
    let l:result = s:call(l:cmd)
    if l:result isnot# v:null
      call add(l:results, l:result)
    endif
  endfor
  return len(l:results) > 0 ? l:results : v:null
endfunction

function! s:call(cmd) abort
  try
    let l:result = {'result': call(a:cmd.method, a:cmd.params)}
  catch
    let l:result = {
          \ 'error': {
          \   'code': 1,
          \   'message': v:exception .. "\n" .. v:throwpoint,
          \ }
          \}
  endtry
  if !has_key(a:cmd, 'id')
    return v:null
  endif
  return extend({'jsonrpc': '2.0', 'id': a:cmd.id}, l:result)
endfunction
