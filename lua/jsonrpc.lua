local uv = vim.loop

local function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

local function lines(str)
  local t = {}
  local function helper(line)
    table.insert(t, line)
    return ""
  end

  helper((str:gsub("(.-)\r?\n", helper)))
  return t
end

local function is_array(table)
  if type(table) ~= 'table' then
    return false
  end

  -- objects always return empty size
  if #table > 0 then
    return true
  end

  -- only object can have empty length with elements inside
  for k, v in pairs(table) do
    return false
  end

  -- if no elements it can be array and not at same time
  return true
end

local function call(cmd)
  local status, result = pcall(function()
    return vim.api.nvim_call_function(cmd.method, cmd.params)
  end)
  local response
  if status then
    response = { result = result }
  else
    response = { error = { code = 1, message = result } }
  end
  table.insert(response, { jsonrpc = "2.0" })
  if cmd.id ~= nil then
    table.insert(response, { id = cmd.id })
  end
  return response
end

local function batch(cmds)
  local results = {}
  for _, cmd in ipairs(cmds) do
    local result = call(cmd)
    if cmd.id ~= nil then
      table.insert(results, result)
    end
  end
  return results
end

local function dispatch(cmd)
  if is_array(cmd) then
    return batch(cmd)
  else
    return call(cmd)
  end
end

local function on_receive(chan, previous, chunk)
  local records = lines(previous .. chunk)
  local next_previous = table.remove(records)
  for _, record in ipairs(records) do
    if record ~= nil then
      local response = dispatch(vim.json.decode(record))
      if response ~= nil then
        chan:write(vim.json.encode(response))
      end
    end
  end
  return next_previous
end

local function close(chan)
  chan:shutdown()
  chan:close()
end

local function connect(host, port)
  local chan = uv.new_tcp()
  chan:connect(host, port, function(err_connect)
    assert(not err_connect, err_connect)

    local previous = ""
    chan:read_start(function(err, chunk)
      assert(not err, err)
      if chunk then
        vim.schedule(function()
          previous = on_receive(chan, previous, chunk)
        end)
      else
        close(chan)
      end
    end)
  end)

  return
end

return {
  connect = connect,
  close = close,
}
