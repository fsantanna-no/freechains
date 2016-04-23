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

function SERVER (t)
    for k,v in pairs(t) do
        APP.server[k] = v
    end
end

function CLIENT (t)
    for k, v in pairs(t) do
        APP.client[k] = v
    end
end

local meta = {
    __index = function (t,k)
        if type(k) == 'number' then
            return APP.genesis
        end
    end,
}

function CHAINS (t)
    for k, tid in pairs(t) do
        APP.chains[k] = tid
        if type(tid) == 'table' then
            assert(type(tid.zeros) == 'number')
            if k == '' then
                assert(tid.zeros < 256)
            end
            tid.heads = setmetatable({}, meta)
        end
    end
end

function BLOCKS (t)
    --
end

function MESSAGE (t)
    local major,minor = string.match(t.id,'(%d+)%.(%d+)')
    t.id_t = {
        major = major,
        minor = minor,
    }
    if t.id == '1.0' then
        assert(type(t.chain)=='table')
        assert(type(t.chain.zeros)=='number')
        local cfg = assert(APP.chains[t.chain.key],t.chain.key)
        assert(t.chain.zeros >= cfg.zeros)
    end
    assert(not APP.message)
    APP.message = t
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
