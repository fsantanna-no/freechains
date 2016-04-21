-- server configurations
SERVER {
    host = { '127.0.0.1', '8330' },
    backlog = 128,
    message10_payload_len_limit = 1000,   -- max payload length for untrusted clients
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
    BACK_HASH_JUMP_LIMIT = 10,
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
