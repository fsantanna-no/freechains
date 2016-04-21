SERVER {
    host = { '127.0.0.1', '8332' },
}

CLIENT {
    peers = {
        { '127.0.0.1', '8331' },
    },
}

-- chains configurations
local levels = {}
for i=0, 22 do
    levels[i] = {
        head = string.rep('\0',32), -- current chain head
    }
end

CHAINS {
    ['fsantanna'] = {       -- chain id
        signed = true,      -- messages are signed
        --signed = false,   -- messages are not signed
        --mode = 'pub'      -- only publishes messages (storage required)
        --mode = 'sub'      -- only listen for messages (storeage not required)
        --mode = 'pub/sub'?
        [0] = levels[0],
        unpack(levels),
    },
}
