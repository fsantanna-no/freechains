local __genesis = string.rep('\0',32) -- genesis block for all chains

APP = {
    genesis  = __genesis,
    server   = {},  -- server configurations
    client   = {},  -- client configurations
    chains   = {},  -- chains configurations
    blocks   = {    -- blocks in memory
        [__genesis] = {
            block_hash = __genesis,
            tail_hash  = nil,
            payload    = '',
        }
    },
    messages = {},  -- pending messages to transmit
}

local meta = {
    __index = function (t,k)
        if type(k) == 'number' then
            return APP.genesis
        end
    end,
}

local function chain_parse (key, chain)
    assert(type(chain) == 'table')
    chain.key = key
    assert(type(chain.zeros) == 'number')
    if k == '' then
        assert(chain.zeros < 256)
    end
    chain.heads = setmetatable({}, meta)
end

function SERVER (t)
    assert(type(t) == 'table')
    for k,v in pairs(t) do
        APP.server[k] = v
    end
    t = APP.server
    assert(type(t.chains) == 'table')
    for key,chain in pairs(t.chains) do
        chain_parse(key, chain)
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
        for key,chain in pairs(peer.chains) do
            chain_parse(key, chain)
        end
    end
end

function BLOCKS (t)
    --
end

function MESSAGE (t)
    if t.id == '1.0' then
        assert(type(t.chain)=='table')
        assert(type(t.chain.zeros)=='number')
        local cfg = assert(APP.server.chains[t.chain.key],t.chain.key)
        assert(t.chain.zeros >= cfg.zeros)
    end
    APP.messages[#APP.messages+1] = t
end

function APP.chain_length (up, down)
    local len = 0
    local hash = up
    while hash ~= down do
        len = len + 1
        local tail_hash = assert(assert(APP.blocks[hash]).tail_hash)
        hash = assert(assert(APP.blocks[tail_hash]).block_hash)
    end
    return len
end

function hex_dump(buf)
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
