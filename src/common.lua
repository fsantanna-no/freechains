APP = {
    server    = {},  -- server configurations
    client    = {},  -- client configurations
    chains    = {},  -- chains configurations
    hashes_0s = {},  -- blocks in memory
    messages  = {},  -- pending messages to transmit
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

function CHAINS (t)
    for k, tid in pairs(t) do
        assert(type(tid) == 'table')
        APP.chains[k] = tid
        if k == '' then
            assert(tid.signed == false)
        end
        for i=0, #tid do
            local tz = tid[i]
            assert(type(tz) == 'table')
            assert(type(tz.head)=='string' and
                   string.len(tz.head)==32)
        end
    end
end

function HASHES_0s (t)
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

        local tid = assert(APP.chains[t.chain.key])
        assert(#tid >= t.chain.zeros)
        t.chain.config = tid[t.chain.zeros]
    end
    APP.messages[#APP.messages+1] = t
end
