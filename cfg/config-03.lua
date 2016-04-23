SERVER {
    host = { '127.0.0.1', '8333' },

    chains = {
        [''] = {                -- global chain (cannot be signed)
            zeros = 0,          -- receive messages with 0 leading zeros in the hash
        },
    },
}

CLIENT {
    peers = {
    },
}

