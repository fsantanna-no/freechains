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
        zeros = 0,          -- receive messages with 0 leading zeros in the hash
        --mode = 'pub'      -- only publishes messages (storage required)
        --mode = 'sub'      -- only listen for messages (storeage not required)
        --mode = 'pub/sub'?
    },
}

-- blocks in memory
BLOCKS {
}
