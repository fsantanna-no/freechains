SERVER {
    host = { '127.0.0.1', '8332' },

    chains = {
        [''] = {                -- global chain (cannot be signed)
            zeros = 0,          -- receive messages with 0 leading zeros in the hash
        },
        ['news'] = {            -- chain id
            zeros = 0,          -- unsigned,
            --heads = {},       -- head hash for each sub-chain
        },
        ['fsantanna'] = {       -- chain id
            zeros = 256,        -- signed,
            --heads = {},       -- head hash for each sub-chain
        },
    },
}

CLIENT {
    peers = {
        {
            host = { '127.0.0.1', '8333' },
            chains = {
                [''] = {
                    zeros = 0,
                }
            },
        },
    },
}

