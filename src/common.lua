APP = {
    server   = {},
    client   = {},
    commands = {},
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

function CONTENTS (t)
    --APP.commands[#APP.commands] = t
    APP.contents = t
end
