if !has('vim9script')
  function! jsonrpc#vim#Connect(host, port) abort
    return jsonrpc#vim8#Connect(a:host, a:port)
  endfunction

  function! jsonrpc#vim#Close(chan) abort
    return jsonrpc#vim8#Close(a:chan)
  endfunction

  finish
endif
vim9script

import autoload 'jsonrpc/vim9.vim'

export def Connect(host: string, port: number): channel
  return vim9.Connect(host, port)
enddef

export def Close(chan: channel): void
  call vim9.Close(chan)
enddef
