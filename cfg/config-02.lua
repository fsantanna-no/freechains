SERVER {
    host = { '127.0.0.1', '8332' },
}

CLIENT {
    peers = {
        { '127.0.0.1', '8331' },
    },
}

CHAINS {
    ['fsantanna'] = {       -- chain id
        [true] = {
            zeros = 22,
        },
        [false] = false,
    },
}
