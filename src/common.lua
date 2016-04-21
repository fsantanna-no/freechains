APP = {
    server   = {},  -- server configurations
    client   = {},  -- client configurations
    chains   = {},  -- chains configurations
    blocks   = {},  -- blocks in memory
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
            return string.rep('\0',32) -- genesis block
        end
    end,
}

function CHAINS (t)
    for k, tid in pairs(t) do
        APP.chains[k] = tid
        assert(type(tid) == 'table')
        if k == '' then
            assert(tid[true] == false)
        end
        for _, signed in ipairs{true,false} do
            local tsig = tid[signed]
            if tsig == false then
                tsig = {}
                tid[signed] = tsig
            else
                assert(type(tsig) == 'table')
                assert(type(tsig.zeros) == 'number')
            end
            tsig.heads = {}
            setmetatable(tsig.heads, meta)
        end
        if k~='' and tid[false].zeros then
            -- asserts that if "unsigned" is sub'ed, than "signed" must also be
            assert(tid[true].zeros and tid[false].zeros<=tid[true].zeros)
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
        assert(type(t.chain.zeros=='number'))
        assert(type(t.chain.signed=='bool'))

        t.chain.config = assert(APP.chains[t.chain.key],t.chain.key)
        assert(type(t.chain.config) == 'table')
        assert(t.chain.config[true]~=nil and t.chain.config[false]~=nil)
    end
    APP.messages[#APP.messages+1] = t
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
