local FC = {
    chains = {
        --[id] = {...}
    },
    errs = {
        -- NOTSUB, etc
    },
}

-------------------------------------------------------------------------------

function FC.chain_block_get (chain, hash)
    local cur = chain.head
    while cur do
        if cur.hash == hash then
            return cur
        end
        cur = cur.prv
    end
    return nil
end

function FC.chain_flatten (id)
    local key,zeros = string.match(id,'|(.*)|(.*)|')
    local chain = assert(FC.chains[key][tonumber(zeros)])
    local cur = chain.head
    local T = {}
    while cur do
        local t = {
            hash = FC.tostring(cur.hash),
            length = cur.length,
            pub = cur.pub and {
                hash    = cur.pub.hash,
                payload = cur.pub.payload,
            },
        }
        table.insert(T, 1, t)
        cur = cur.prv
    end
    return T
end

function FC.chain_tostring (id)
    return FC.tostring(FC.chain_flatten(id))
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

local socket = require 'socket'
function FC.send (tp, msg, daemon)
    daemon = daemon or FC.daemon
    local c = assert(socket.connect(daemon.address,daemon.port))
    msg = FC.tostring(msg, 'plain')
    local buffer = 'PS'..string.char((tp>>8) & 0xFF)
                       ..string.char(tp      & 0xFF)
    do
        local len = string.len(msg)
        assert(len <= 0xFFFFFFFF)
        buffer = buffer..string.char((len>>24) & 0xFF)
                       ..string.char((len>>16) & 0xFF)
                       ..string.char((len>> 8) & 0xFF)
                       ..string.char(len       & 0xFF)
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
        return assert(load('return '..tostring(ret)))()
    end
end

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
