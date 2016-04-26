APP = {
    server   = {},  -- server configurations
    client   = {},  -- client configurations
    chains   = {},  -- chains configurations
    messages = {},  -- pending messages to transmit
    blocks = {      -- blocks in memory
        --[hash] = {
        --    hash      = nil,
        --    up_hash   = nil,
        --    tail_hash = nil,
        --    txs       = { tx_hash1, tx_hash2, ... },
        --},
        ...
    },
    txs = {         -- txs in memory
        --[hash] = {
        --    hash      = nil,
        --    timestamp = nil,
        --    bytes     = nil,
        --    payload   = nil,
        --}
    },
    gs = {          -- ceu->lua globals
        --[usedata-k] = {}
    }
}

local chain_create
function SERVER (t)
    assert(type(t) == 'table')
    for k,v in pairs(t) do
        APP.server[k] = v
    end
    t = APP.server
    assert(type(t.chains) == 'table')
    for _,chain in ipairs(t.chains) do
        APP.chains.parse(chain)
        if not APP.chains[chain.id] then
            APP.chains[chain.id] = chain_create(chain)
        end
    end
end

function CLIENT (t)
    assert(type(t) == 'table')
    for k, v in pairs(t) do
        APP.client[k] = v
    end
    t = APP.client
    assert(type(t.peers) == 'table')

    for _, peer in ipairs(t.peers) do
        assert(type(peer) == 'table')
        assert(type(peer.chains) == 'table')
        for _,chain in ipairs(peer.chains) do
            local c = APP.chains.parse(chain)
            assert(c)   -- must already exist
        end
    end
end

function BLOCKS (t)
    --
end

function MESSAGE (t)
    APP.messages[#APP.messages+1] = t
end

-------------------------------------------------------------------------------

function APP.chains.parse (chain)
    assert(type(chain) == 'table')
    assert(type(chain.key)   == 'string')
    assert(type(chain.zeros) == 'number')
    if chain.key == '' then
        assert(chain.zeros < 256)
    end
    chain.id = '|'..chain.key..'|'..chain.zeros..'|'
    return APP.chains[chain.id]
end

function APP.chains.head_base_len (head)
    local cur = head
    local len = 1
    while cur.tail_hash do
        len = len + 1
        cur = APP.blocks[cur.tail_hash]
    end
    return {
        base = cur,
        head = head,
        len  = len
    }
end

-- TODO: go back only TODO jumps
function APP.chains.tx_contains (head, tx_hash)
    local cur = head
    while cur.tail_hash do
        for _, tx_hash_i in ipairs(cur.txs) do
            if tx_hash_i == tx_hash then
                return true
            end
        end
        cur = APP.blocks[cur.tail_hash]
    end
    return false
end

function APP.chains.tostring (chain)
    local head = APP.blocks[chain.head_hash]
    local T = {}
    while head do
        local str = tostring2(head.hash)
              str = string.sub(str,11,11+10)
        local t = {
            hash = str,
            txs  = {},
        }
        table.insert(T, 1, t)
        for i, tx in ipairs(head.txs) do
            local str = string.sub(APP.txs[tx].payload,1,10)
                  str = string.gsub(str,'%c','.')
            t.txs[i] = string.sub(str,1,10)
        end
        head = APP.blocks[head.tail_hash]
    end
    return tostring2(T)
end

-------------------------------------------------------------------------------

chain_create = function (chain)
    local tx_hash = chain.id          -- TODO: should be hash(chain.id)
    tx_hash = chain.id..string.rep('\0',32-string.len(chain.id))
    APP.txs[tx_hash] = {
        hash      = tx_hash,
        timestamp = 0,
        bytes     = 0,
        payload   = '',
    }

    -- chain.head_hash
    local block_hash = tx_hash  -- TODO: should be hash of txs merkle tree
    local block_genesis = {
        hash = block_hash,
        txs  = { tx_hash },
    }
    APP.blocks[block_hash] = block_genesis
    chain.head_hash = block_hash

    return chain
end

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

-------------------------------------------------------------------------------
-- 3rd-party code
-------------------------------------------------------------------------------

local function string2hex(buf)
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
    return ret
end

function tostring2( tbl )
    if  "nil"       == type( tbl ) then
        return tostring(nil)
    elseif  "table" == type( tbl ) then
        return table_show(tbl)
    elseif  "string" == type( tbl ) then
        if is_binary(tbl) then
            return string2hex(tbl)
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
function table_show(t, name, indent)
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
         return string.format("%q", tostring2(o))
      else
         return string.format("%q", so)
      end
   end

   local function addtocart (value, name, indent, saved, field)
      indent = indent or ""
      saved = saved or {}
      field = field or name

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
            if isemptytable(value) then
               cart = cart .. " = {};\n"
            else
               cart = cart .. " = {\n"
               for k, v in pairs(value) do
                  k = basicSerialize(k)
                  local fname = string.format("%s[%s]", name, k)
                  field = string.format("[%s]", k)
                  -- three spaces between levels
                  addtocart(v, fname, indent .. "   ", saved, field)
               end
               cart = cart .. indent .. "};\n"
            end
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
