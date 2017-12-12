local FC = {
    chains = {
        --[id] = {...}
    },
    errs = {
        -- NOTSUB, etc
    },
}

-------------------------------------------------------------------------------

local function max (a, b)
    return a>b and a or b
end

function FC.node (node)
    assert(node.hash,  'missing hash')
    assert(node.chain, 'missing chain')

    local old = node.chain.cache[node.hash]
    if old then
        old.__from_cache = true
        return old
    end
    node.chain.n = node.chain.n + 1
    node.chain.cache[node.hash] = node

    node.height = -1
    for _, a in ipairs(node) do
        assert(a.chain == node[1].chain)
        node.height = max(node.height, a.height)
    end
    node.height = node.height + 1

    return node
end

function FC.children (node, head)
    for k,v in pairs(head) do
        node[#node+1] = v
    end
    table.sort(node, function(a,b) return a.hash<b.hash end)
            -- TODO-01: remover este

    local t = {}
    for _, a in ipairs(node) do
        t[#t+1] = FC.tostring(a.hash)
    end
end

function FC.head_new (node)
    node.chain.head[node.hash] = node
    for _,v in ipairs(node) do
        node.chain.head[v.hash] = nil
    end
end

local function dot_aux (A, t)
    if t.cache[A] then
        return
    else
        --t.cache[A] = 'n_'..string.gsub(FC.tostring(A.hash),' ','_')
        t.cache[A] = 'n_'..string.format('%03d',t.n)
        --t.cache[A] = 'n_'..string.format('%03d',A.height)..'_'..string.format('%03d',t.n)
            -- TODO-01: usar este em vez do sem o height
        t.n = t.n + 1
    end

    --table.sort(A, function(a,b) return a.pub.payload<b.pub.payload end)
    --table.sort(A, function(a,b) return a.hash<b.hash end)
            -- TODO-01: usar este em vez de em FC.children
    for _, a in ipairs(A) do
        dot_aux(a, t)
        t.conns[#t.conns+1] = t.cache[A]..' -> '..t.cache[a]
    end

    --local label = A.label or (A.hash and FC.tostring(A.hash)) or t.cache[A]
    local label = A.label or (A.pub and A.pub.payload) or (A.hash and FC.tostring(A.hash)) or t.cache[A]
    --t.nodes[#t.nodes+1] = t.cache[A]..'[label="'..label..'/'..A.height..'", shape='..SHAPE[A.tp]..'];'
    t.nodes[#t.nodes+1] = t.cache[A]..'[label="'..label..'/'..A.height..'"];'
end

function FC.dot (A, path)
    local t = { n=0, cache={}, nodes={}, conns={} }
    local head = { height=-1, label='head' }
    for _,v in pairs(A) do
        head[#head+1] = v
        head.height = max(head.height, v.height)
    end
    head.height = 0 --head.height + 1
                        -- TODO-01: usar este em vez do "0"
    table.sort(head, function(a,b) return a.hash<b.hash end)
    --table.sort(head, function(a,b) return a.pub.payload<b.pub.payload end)
    dot_aux(head, t)

    table.sort(t.nodes)
    table.sort(t.conns)

    local f = (path and assert(io.open(path,'w'))) or io.stdout
    f:write([[
    digraph graphname {
        //rankdir=LR;  // Rank Direction Left to Right

        nodesep=1.0 // increases the separation between nodes
        edge [];
        //splines = true;

        ]]..table.concat(t.nodes,'\n')..[[

        ]]..table.concat(t.conns,'\n')..[[

    }
    ]])
    f:close()
end

-------------------------------------------------------------------------------

local function write_aux (A, t)
    if t.cache[A] then
        return
    else
        t.cache[A] = true
    end

    local out = {
        chain     = nil,
        height    = nil,
        --
        hash      = A.hash,
        nonce     = A.nonce,
        timestamp = A.timestamp,

        pub = A.pub and {
            chain      = nil,
            --
            hash       = A.pub.hash,
            nonce      = A.pub.nonce,
            timestamp  = A.pub.timestamp,
            payload    = A.pub.payload,
            --remove_src = A.pub.remove_src and A.pub.remove_src.hash,
        } or nil,
    }
    for i, v in ipairs(A) do
        write_aux(v, t)
        out[i] = v.hash
    end
    t.nodes[#t.nodes+1] = 'Node('..FC.tostring(out,'plain')..')'
end

function FC.write (chain, path)
    local t = { cache={}, nodes={} }

    local head = {}
    for _,v in pairs(chain.head) do
        head[#head+1] = v
    end
    table.sort(head, function(a,b) return a.hash<b.hash end)
    --table.sort(head, function(a,b) return a.pub.payload<b.pub.payload end)

    for i,v in ipairs(head) do
        write_aux(v, t)
        head[i] = v.hash
    end


    local f = (path and assert(io.open(path,'w'))) or io.stdout
    f:write([[
        ]] .. table.concat(t.nodes,'\n') .. [[
        Head(]]..FC.tostring(head,'plain')..[[)
    ]])
    f:close()
end

-------------------------------------------------------------------------------

function FC.read (chain, path)
    function Node (node)
        node.chain = chain
        if node.pub then
            node.pub.chain = chain
        end
        chain.cache[node.hash] = node
        chain.n = chain.n + 1

        node.height = -1
        for i, hash in ipairs(node) do
            node[i] = assert(chain.cache[hash])
            node.height = max(node.height, node[i].height)
        end
        node.height = node.height + 1
    end

    function Head (t)
        chain.head = {}
        for _, hash in ipairs(t) do
            chain.head[hash] = assert(chain.cache[hash])
        end
    end

    dofile(path)
end

-------------------------------------------------------------------------------

function FC.cfg_write ()
    local f = assert(io.open(arg[1],'w'))
    for k,v in pairs(CFG) do
        f:write(k..' = '..FC.tostring(v,'plain')..'\n')
    end
    f:close()
end

-------------------------------------------------------------------------------

local function is_binary (str)
    return (string.gsub(str,'%c','') ~= str)
--[[
    assert(type(str)=='string')
    for i=1, string.len(str) do
        if string.byte(str,i) < string.byte(' ') or
            string.byte(str,i) > string.byte('~') then
            return true
        end
    end
]]
end

function FC.hash2hex (hash)
    local ret = ''
    for i=1, string.len(hash) do
        ret = ret .. string.format('%02X', string.byte(string.sub(hash,i,i)))
    end
    return ret
end

function FC.hex2hash (hex)
    local ret = ''
    for i=1, string.len(hex), 2 do
        local n = tonumber('0x'..string.sub(hex,i,i+1))
        if not n then
            return nil
        end
        ret = ret .. string.char(n)
    end
    return ret
end

function FC.escape (html)
    return (string.gsub(html, "[}{\">/<'&]", {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&quot;",
        ["'"] = "&#39;",
        ["/"] = "&#47;"
    }))
end -- https://github.com/kernelsauce/turbo/blob/master/turbo/escape.lua

-------------------------------------------------------------------------------

local function byte (v, n)
    local m = 0
    for i=0, n do
        m = v % 256
        v = math.floor(v / 256)
    end
    return m
end

local socket = require 'socket'
function FC.send (tp, msg, daemon)
    daemon = daemon or FC.daemon
    local c = assert(socket.connect(daemon.address,daemon.port))
    msg = FC.tostring(msg, 'plain')
    --local buffer = 'PS'..string.char((tp>>8)&0xFF, tp&0xFF)
    local buffer = 'PS'..string.char(byte(tp,1), byte(tp,0))
    do
        local len = string.len(msg)
        assert(len <= 0xFFFFFFFF)
        --buffer = buffer..string.char((len>>24)&0xFF, (len>>16)&0xFF,
                                     --(len>> 8)&0xFF, (len>> 0)&0xFF)
        buffer = buffer..string.char(byte(len,3), byte(len,2), byte(len,1), byte(len,0))
    end
    buffer = buffer .. msg
    assert(c:send(buffer))

    if tp == 0x0600 then
        while true do
            local n = c:receive('*l')
            print(n)
            local ret = c:receive(assert(tonumber(n)))
            print(ret)
        end
    else
        local ret = c:receive('*a')
        --print('<<<', string.format('%q',ret))
        c:close()
        if _VERSION == 'Lua 5.1' then
            return assert(loadstring('return '..tostring(ret)))()
        else
            return assert(load('return '..tostring(ret)))()
        end
    end
end

local function one (node, cache, daemon)
    if cache[node.hash] then
        return
    end

    coroutine.yield(node)

    for _, hash in ipairs(node) do
        local childs = FC.send(0x0200, {    -- GET
            chain = { key=node.chain.key, zeros=node.chain.zeros },
            node  = hash,
        }, daemon)
        assert(#childs == 1)
        one(childs[1], cache, daemon)
    end
end

function FC.get_iter (chain, cache, daemon)
    return coroutine.wrap(
        function ()
            local head = FC.send(0x0200, {    -- GET
                chain = { key=chain.key, zeros=chain.zeros },
            }, daemon)

            for i, node in ipairs(head) do
                one(node, cache, daemon)
            end
        end
    )
end

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 3rd-party code
-------------------------------------------------------------------------------

local function string2hex(buf, big)
    local ret = ''
    for byte=1, #buf, 16 do
        local chunk = buf:sub(byte, byte+15)
        ret = ret .. string.format('%08X  ',byte-1)
        chunk:gsub('.',
            function (c)
                ret = ret .. string.format('%02X ',string.byte(c))
            end)
        ret = ret .. string.rep(' ',3*(16-#chunk))
        ret = ret .. ' '..chunk:gsub('%c','.')..'\n'
    end
    if not big then
        ret = string.sub(ret,11,11+10)
    end
    return ret
end

--[[
   Author: Julio Manuel Fernandez-Diaz
   Date:   January 12, 2007
   (For Lua 5.1)
   
   Modified slightly by RiciLake to avoid the unnecessary table traversal in tablecount()

   Formats tables with cycles recursively to any depth.
   The output is returned as a string.
   References to other tables are shown as values.
   Self references are indicated.

   The string returned is "Lua code", which can be procesed
   (in the case in which indent is composed by spaces or "--").
   Userdata and function keys and values are shown as strings,
   which logically are exactly not equivalent to the original code.

   This routine can serve for pretty formating tables with
   proper indentations, apart from printing them:

      print(table.show(t, "t"))   -- a typical use
   
   Heavily based on "Saving tables with cycles", PIL2, p. 113.

   Arguments:
      t is the table.
      name is the name of the table (optional)
      indent is a first indentation (optional).
--]]
local function table_show(t, name, indent, mode)
   local cart     -- a container
   local autoref  -- for self references

   --[[ counts the number of elements in a table
   local function tablecount(t)
      local n = 0
      for _, _ in pairs(t) do n = n+1 end
      return n
   end
   ]]
   -- (RiciLake) returns true if the table is empty
   local function isemptytable(t) return next(t) == nil end

   local function basicSerialize (o)
      local so = tostring(o)
      if type(o) == "function" then
         local info = debug.getinfo(o, "S")
         -- info.name is nil because o is not a calling level
         if info.what == "C" then
            return string.format("%q", so .. ", C function")
         else 
            -- the information is defined through lines
            return string.format("%q", so .. ", defined in (" ..
                info.linedefined .. "-" .. info.lastlinedefined ..
                ")" .. info.source)
         end
      elseif type(o) == "number" or type(o) == "boolean" then
         return so
      elseif type(o) == "string" then
         return FC.tostring(o,mode)
         --return string.format("%q", FC.tostring(o,big))
      else
         return string.format("%q", so)
      end
   end

   local FIRST = true

   local function addtocart (value, name, indent, saved, field)
      indent = indent or ""
      saved = saved or {}
      field = field or name
      local first = FIRST
      FIRST = false

      cart = cart .. indent .. field

      if type(value) ~= "table" then
         cart = cart .. " = " .. basicSerialize(value) .. ";\n"
      else
         if saved[value] then
            cart = cart .. " = {}; -- " .. saved[value] 
                        .. " (self reference)\n"
            autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
         else
            saved[value] = name
            --if tablecount(value) == 0 then
            if first then
               cart = ""
            else
               cart = cart .. " = "
            end
            if isemptytable(value) then
               cart = cart .. "{}"
            else
               cart = cart .. "{\n"

               local t = {}
               for k in pairs(value) do
                  t[#t+1] = k
               end
               table.sort(t, function(a,b) return tostring(a)<tostring(b) end)

               for _, k in ipairs(t) do
                  local v = value[k]
                  k = basicSerialize(k)
                  local fname = string.format("%s[%s]", name, k)
                  field = string.format("[%s]", k)
                  -- three spaces between levels
                  addtocart(v, fname, indent .. "   ", saved, field)
               end
               cart = cart .. indent .. "}"
            end
            cart = cart .. (first and "" or ";").."\n"
         end
      end
   end

   name = name or "__unnamed__"
   if type(t) ~= "table" then
      return name .. " = " .. basicSerialize(t)
   end
   cart, autoref = "", ""
   addtocart(t, name, indent)
   return cart .. autoref
end

-------------------------------------------------------------------------------

function FC.tostring (tbl, mode)
    if "table" == type(tbl) then
        return table_show(tbl,nil,nil,mode)
    elseif "string" == type(tbl) then
        if mode == 'plain' then
            return string.format("%q", tbl)
        elseif is_binary(tbl) then
            return string2hex(tbl, mode)
        else
            return tbl
        end
    else
        return tostring(tbl)
    end
end

return FC
