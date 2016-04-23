-- global configurations
BACK_HASH_JUMP_LIMIT = 10,

-- server configurations
SERVER {
    host = { '127.0.0.1', '8330' },
    backlog = 128,
    message10_payload_len_limit = 1024,   -- max payload length for untrusted clients

    -- subscribed chains
    chains = {
        [''] = {                -- global chain (cannot be signed)
            zeros = 0,          -- receive messages with 0 leading zeros in the hash
            --mode = 'pub'      -- only publishes messages (storage required)
            --mode = 'sub'      -- only listen for messages (storeage not required)
            --mode = 'pub/sub'?
        },
    },
}

-- client configurations
CLIENT {
    -- 8332 -> 8331 -> 8330
    peers = {
        --{
        --    host = { '127.0.0.1', '8331' },
        --    chains = {
        --        [''] = {
        --            zeros = 0,
        --        }
        --    },
        --},
    },
}

-- blocks in memory
BLOCKS {
}
