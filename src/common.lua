APP = {
    server   = {},
    client   = {},
    messages = {},
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

function MESSAGE (t)
    local major,minor = string.match(t.id,'(%d+)%.(%d+)')
    t.id_t = {
        major = major,
        minor = minor,
    }
    APP.messages[#APP.messages+1] = t
end
