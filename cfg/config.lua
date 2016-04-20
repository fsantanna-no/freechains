-- server configurations
SERVER {
    host = { '127.0.0.1', '8330' },
    backlog = 128,
}

-- client configurations
CLIENT {
    -- 8332 -> 8331 -> 8330
    peers = {
        --{ '127.0.0.1', '8331' },
        --{ '127.0.0.1', '8332' },
    },
}

-- chains configurations
CHAINS {
    [''] = {                -- global chain (cannot be signed)
        --signed = true,    -- messages are signed
        signed = false,     -- messages are not signed
        --mode = 'pub'      -- only publishes messages (storage required)
        --mode = 'sub'      -- only listen for messages (storeage not required)
        --mode = 'pub/sub'?
        [0] = {                 -- chain-00
            head = string.rep('\0',32), -- current chain head
        },
    },
}

-- blocks in memory
HASHES_0s {
}
