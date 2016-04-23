SERVER {
    host = { '127.0.0.1', '8332' },
}

CLIENT {
    peers = {
        {
            host = { '127.0.0.1', '8331' },
        },
    },
}

CHAINS {
    ['news'] = {            -- chain id
        zeros = 0,          -- unsigned,
        --heads = {},       -- head hash for each sub-chain
    },
    ['fsantanna'] = {       -- chain id
        zeros = 256,        -- signed,
        --heads = {},       -- head hash for each sub-chain
    },
}
