FC = {
    chains = {
        --[id] = {...}
    },
    errs = {
        -- NOTSUB, etc
    },
}

-------------------------------------------------------------------------------

function FC.chain_create (key, zeros)
    FC.chains[key] = FC.chains[key] or {}
    assert(not FC.chains[key][zeros])
    local id = '|'..key..'|'..zeros..'|'
    local new = {
        key   = key,
        zeros = zeros,
        id    = id,
        cfg   = nil,
        head  = nil,
        base  = nil,
        last_output = nil,
    }
    FC.chains[key][zeros] = new
    return new
end

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
            hash = tostring2(cur.hash),
            length = cur.length,
            publication = cur.publication and {
                hash    = cur.publication.hash,
                payload = cur.publication.payload,
            },
        }
        table.insert(T, 1, t)
        cur = cur.prv
    end
    return T
end

function FC.chain_tostring (id)
    return tostring2(FC.chain_flatten(id))
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

function tostring2 (tbl, mode)
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
function table_show(t, name, indent, mode)
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
         return tostring2(o,mode)
         --return string.format("%q", tostring2(o,big))
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
               table.sort(t)

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
