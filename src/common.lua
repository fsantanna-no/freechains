--assert = function (...) return (...) end

GG = {}

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
        --...
    },
    txs = {         -- txs in memory
        --[hash] = {
        --    hash    = nil,
        --    nonce   = nil,
        --    bytes   = nil,
        --    payload = nil,
        --}
    },
    gs = {          -- ceu->lua globals
        --[usedata-k] = {}
    },
    errs = {
        -- NOTSUB, etc
    },
}

function CHAINS (t)
    assert(type(t) == 'table')
    APP.chains = {                     -- substitutes old
        files = t.files or APP.chains.files,
    }
    for _,chain in ipairs(t) do
        for i=chain.zeros,255 do
            local new = {}
            for k,v in pairs(chain) do new[k]=v end
            new.zeros = i
            local c = GG.chain_parse_get(new)
            assert(not APP.chains[new.id], new.id)
            APP.chains[new.id] = (c or new)
            APP.chains[#APP.chains+1] = APP.chains[new.id]
        end
    end
end

function SERVER (t)
    assert(type(t) == 'table')
    for k,v in pairs(t) do
        APP.server[k] = v
    end
    APP.server.timeout = APP.server.timeout or 10
    APP.server.backlog = APP.server.backlog or 128
    APP.server.message10_payload_len_limit = APP.server.message10_payload_len_limit or 1024 -- max payload length for untrusted clients
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
        if peer.chains then
            assert(type(peer.chains) == 'table')
            for _,chain in ipairs(peer.chains) do
                local c = GG.chain_parse_get(chain)
                assert(c)   -- must already exist
            end
        else
            peer.chains = APP.chains
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

function GG.chain_parse_get (chain)
    assert(type(chain) == 'table')
    assert(type(chain.key)   == 'string')
    assert(type(chain.zeros) == 'number')
    if chain.key == '' then
        assert(chain.zeros < 256)
    end
    chain.id = '|'..chain.key..'|'..chain.zeros..'|'
    -- WARNING: do not reset other fields here
    return APP.chains[chain.id]
end

function GG.chain_head_base_size (head_hash)
    local head = APP.blocks[head_hash]
    local cur  = head
    local size = 1  -- genesis TX
    while cur.tail_hash do
        size = size + #cur.txs
        cur = APP.blocks[cur.tail_hash]
    end
    return {
        base = cur,
        head = head,
        size = size,     -- TODO: #payload
    }
end

function GG.chain_block (chain, hash)
    local cur = chain.head
    while cur do
        if cur.hash == hash then
            return cur
        end
        cur = cur.prv
    end
    return nil
end

-- TODO: go back only TODO jumps
function GG.chain_tx_contains (head_hash, tx_hash)
    local cur = APP.blocks[head_hash]
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

function GG.chain_flatten (chain_id)
    local chain = assert(APP.chains[chain_id],chain_id)
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

function GG.chain_tostring (chain_id)
    return tostring2(GG.chain_flatten(chain_id))
end

--[[
function GG.chain_check (chain_id)
    local str1 = GG.chain_tostring(chain_id)

    base = GG.chain_head_base_size(APP.chains[chain_id].head_hash).base
    T = {}
    while base do
        local t = {
            hash = tostring2(base.hash),
            txs  = {},
        }
        table.insert(T, t)
        for i, tx in ipairs(base.txs) do
            local str = string.sub(APP.txs[tx].payload,1,10)
                  str = string.gsub(str,'%c','.')
            t.txs[i] = string.sub(str,1,10)
        end
        base = APP.blocks[base.up_hash]
    end
    str2 = tostring2(T)

print('=========>\n'..str1..'============='..str2..'<==========')
    assert(str1 == str2)
end
]]

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

-------------------------------------------------------------------------------
-- 3rd-party code
-------------------------------------------------------------------------------

local function string2hex(buf,big)
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

function tostring2 (tbl, big)
    if "nil" == type(tbl) then
        return tostring(nil)
    elseif "table" == type(tbl) then
        return table_show(tbl)
    elseif "string" == type(tbl) then
        if is_binary(tbl) then
            return string2hex(tbl, big)
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
