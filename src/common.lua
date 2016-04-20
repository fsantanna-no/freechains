APP = {
    server    = {},  -- server configurations
    client    = {},  -- client configurations
    hashes_0s = {},  -- hashes owned
    messages  = {},  -- pending messages
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

function HASHES_0s (t)
    --
end

function MESSAGE (t)
    local major,minor = string.match(t.id,'(%d+)%.(%d+)')
    t.id_t = {
        major = major,
        minor = minor,
    }
    APP.messages[#APP.messages+1] = t
end
