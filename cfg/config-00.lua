dir = '/tmp/freechains'

server = {
    address = '127.0.0.1',
    port    = '8330',
    backlog = 128,
    --timeout = 100,
}

chains = {
    zeros_raise = TODO,     -- global and per-chain
    peers = {},             -- global and per-chain
    [1] = {
        key   = '',
        zeros = 0,
        peers = {
            {
                address = '127.0.0.1',
                port    = '8331',
            },
        },
    },
}
